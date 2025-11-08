enum CompetitionContext {
  ownerCreate,
  ownerModify,  // Owner
  participant, // You participate in competition
  viewerAbleToJoin,       // You can see it but not participate
  viewerNotAbleToJoin,       // You can see it but not participate
  invited,
}