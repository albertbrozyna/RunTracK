enum UserRelationshipStatus { // User status for us
  friend,
  pendingSent,  // Sent invitation
  pendingReceived, // received invitation
  notConnected,
  myProfile
}