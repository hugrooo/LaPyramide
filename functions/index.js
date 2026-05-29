const { onValueCreated } = require("firebase-functions/v2/database");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onGameInviteCreated = onValueCreated(
  "/users/{userId}/invites/{inviteId}",
  async (event) => {
    const userId = event.params.userId;
    const inviteData = event.data.val();

    if (!inviteData) {
      return null;
    }

    const { inviterName, roomCode } = inviteData;

    try {
      // Fetch the user's FCM token
      const tokenSnapshot = await admin.database()
        .ref(`/users/${userId}/fcmToken`)
        .once("value");
      
      const fcmToken = tokenSnapshot.val();

      if (!fcmToken) {
        console.log(`No FCM token found for user ${userId}`);
        return null;
      }

      // Build the message payload
      const message = {
        notification: {
          title: "🎮 Invitation reçue !",
          body: `${inviterName || 'Un ami'} vous invite à jouer à La Pyramide !`
        },
        data: {
          roomCode: roomCode,
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        token: fcmToken
      };

      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent message to user ${userId}:`, response);
      return response;
    } catch (error) {
      console.error(`Error sending message to user ${userId}:`, error);
      return null;
    }
  }
);
