enum UserRelationshipStatus { // User status for us
  friend,
  pendingSent,  // Sent invitation
  pendingReceived, // received invitation
  notConnected,
  myProfile,
  competitionPendingSent, // Send invitation to competition
  competitionNotConnected, // No connection
  competitionParticipant  // Participant
}