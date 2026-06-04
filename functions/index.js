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
exports.onFriendRequestCreated = onValueCreated(
  "/friend_requests/{targetUid}/{fromUid}",
  async (event) => {
    const targetUid = event.params.targetUid;
    const requestData = event.data.val();

    if (!requestData) {
      return null;
    }

    const { fromName } = requestData;

    try {
      // Fetch the target user's FCM token
      const tokenSnapshot = await admin.database()
        .ref(`/users/${targetUid}/fcmToken`)
        .once("value");
      
      const fcmToken = tokenSnapshot.val();

      if (!fcmToken) {
        console.log(`No FCM token found for user ${targetUid}`);
        return null;
      }

      // Build the message payload
      const message = {
        notification: {
          title: "👋 Nouvelle demande d'ami !",
          body: `${fromName || 'Quelqu\'un'} veut vous ajouter en ami !`
        },
        data: {
          type: "friend_request",
          click_action: "FLUTTER_NOTIFICATION_CLICK"
        },
        token: fcmToken
      };

      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent friend request notification to user ${targetUid}:`, response);
      return response;
    } catch (error) {
      console.error(`Error sending friend request notification to user ${targetUid}:`, error);
      return null;
    }
  }
);
