import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as fbAdmin from "firebase-admin";
import * as funcLogger from "firebase-functions/logger";

fbAdmin.initializeApp();

const firestoreCollections = {
  Users: "users",
  Alerts: "notifications",
};

const DocKeys = {
  ReceiverId: "uid",
  DeviceTokens: "fcmTokens",
  MsgTitle: "title",
  MsgType: "type",
  RefId: "objectId",
};

const PushSettings = {
  ClickAction: "FLUTTER_NOTIFICATION_CLICK",
  AppName: "RunTracK",
  FallbackContent: "New event",
  DefaultType: "unknown",
};

const errorCodes = [
  "messaging/registration-token-not-registered",
  "messaging/invalid-argument",
];

export const dispatchPushNotification = onDocumentCreated(
  `${firestoreCollections.Alerts}/{docId}`,
  async (triggerEvent) => {
    const eventSnapshot = triggerEvent.data;
    if (!eventSnapshot) {
      funcLogger.log("Event trigger has no data snapshot");
      return;
    }

    const alertData = eventSnapshot.data();
    const receiverId = alertData[DocKeys.ReceiverId];

    if (!receiverId) {
      funcLogger.error(`Missing '${DocKeys.ReceiverId}' in document`);
      return;
    }

    const recipientSnapshot = await fbAdmin.firestore()
      .collection(firestoreCollections.Users)
      .doc(receiverId)
      .get();

    const deviceTokens = recipientSnapshot.data()?.[DocKeys.DeviceTokens];

    if (
      !deviceTokens ||
            !Array.isArray(deviceTokens) ||
            deviceTokens.length === 0
    ) {
      funcLogger.log(`No device tokens found for user: ${receiverId}`);
      return;
    }

    const payloadTitle = PushSettings.AppName;
    const payloadBody = alertData[DocKeys.MsgTitle] ||
            PushSettings.FallbackContent;

    const pushPayload = {
      notification: {
        title: payloadTitle,
        body: payloadBody,
      },
      data: {
        click_action: PushSettings.ClickAction,
        type: alertData[DocKeys.MsgType] || PushSettings.DefaultType,
        objectId: alertData[DocKeys.RefId] || "",
        notificationId: triggerEvent.params.docId,
      },
      tokens: deviceTokens,
    };

    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const deliveryReport = await fbAdmin.messaging().sendEachForMulticast(
                pushPayload as any
      );

      funcLogger.log(
        `Delivery report for ${receiverId}: ` +
                `Success(${deliveryReport.successCount}) / ` +
                `Failures(${deliveryReport.failureCount})`
      );

      // Collect errors while sending
      if (deliveryReport.failureCount > 0) {
        const staleTokens = deliveryReport.responses.reduce(
          (acc: string[], res, index) => {
            const errorCode = res.error?.code;
            if (
              !res.success &&
                            errorCode &&
                            errorCodes.includes(errorCode)
            ) {
              const token = deviceTokens[index];
              if (token) {
                acc.push(token);
              }
            }
            return acc;
          },
          []
        );

        // Delete old token from user
        if (staleTokens.length > 0) {
          funcLogger.log(
            `Purging ${staleTokens.length} stale tokens from database.`
          );

          await fbAdmin.firestore()
            .collection(firestoreCollections.Users)
            .doc(receiverId)
            .update({
              [DocKeys.DeviceTokens]: fbAdmin.firestore.FieldValue.arrayRemove(
                ...staleTokens
              ),
            });
        }
      }
    } catch (err) {
      funcLogger.error("Fatal exception during send:", err);
    }
  }
);
