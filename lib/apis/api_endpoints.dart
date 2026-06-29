
// const String kAudioUrl = 'https://meetlive.fun/public/uploads/audio';
// const String kDomainUrl = 'https://meetlive.fun';
// const String kWsUrl =
//     'ws://meetlive.fun:8084/app/xccgogz0nowt0d4wj1y6?protocol=7&client=js&version=8.4.0-rc2&flash=false';

// const String kDomainUrl = 'http://192.168.0.192:8001';
// const String kWsUrl =
//     'ws://192.168.0.192:8080/app/xccgogz0nowt0d4wj1y6?protocol=7&client=js&version=8.4.0-rc2&flash=false';
const String kDomainUrl = 'https://xeo.dev.sheikhit.net';
const String kAudioUrl = 'https://xeo.dev.sheikhit.net/public/uploads/audio';
const String kWsUrl =
    'ws://xeo.dev.sheikhit.net:8084/app/xccgogz0nowt0d4wj1y6?protocol=7&client=js&version=8.4.0-rc2&flash=false';

///--------------- game part -------------------------------------------------

const String kBaseUrl = kDomainUrl;

const String kMainUrl = '$kDomainUrl/api';

///------------------------- banner ------------------------------------------
const String kBannerList = '$kMainUrl/banners';

///---------------------------register part or user data ---------------------
const String kRegisterUrl = '$kMainUrl/register';
const String kLoginUrl = '$kMainUrl/login';
const String kLoginGoogle = "$kMainUrl/google_login_postapi";
const String kAllUserList = '$kMainUrl/user_listapi';
const String kEarningPost = "$kMainUrl/earning_history";

///---------------------------coin trading post create -----------------------
String kCoinTradingPost({required String userId, required String amount}) =>
    '$kMainUrl/coin_trade/$userId/$amount';

const String kCoinTradingGet =
    '$kMainUrl/coin_trading_history'; //------List show

///--------------------------- follower list show  ---------------------------
const String kFollowerList = '$kMainUrl/all_follower_list';
const String kFollowingList = '$kMainUrl/all_following_list';
const String kMomentFollowerList = '$kMainUrl/show_follow_list';

///------------>----------agency create --------------------------------------
const String kAgencyPostUrl = '$kMainUrl/agency_createapi';
const String kAgencyListUrl = '$kMainUrl/agency_listapi';

const String kAgencyStatusListUrl = '$kMainUrl/agency_request_list';

String kAgencyRequestListUrl({required int id}) =>
    '$kMainUrl/agencyHostRequestListApi/$id';

String kAgencyHostListUrl({required int id}) => '$kMainUrl/allHostOfAgency/$id';

const String kAgencyAceptUrl = '$kMainUrl/host_accept';
String kAgencyRejectUrl = '$kMainUrl/host_reject';

///-------------------- host Verification ------------------------------------
const String kHostStatus = '$kMainUrl/myHostApplicationStatus';
const String kJoinAgency = '$kMainUrl/join_agency';
const String kNewAgencyList = '$kMainUrl/myAgencyListApi';

///------------>---------- withdraw part to Tado app -------------------------
const String kWithdrawUrl = '$kMainUrl/addPaymentMethod';
const String kgetWithdrawList = '$kMainUrl/myPaymentMethodList';
const String kpostWithdraw = '$kMainUrl/withdrow_create';
const String kWithdrawToTradeUrl = '$kMainUrl/coin_treadapi';
const String kExchangeCoinUrl = '$kMainUrl/coin_exchangeapi';
const String kTopUpCoinPost = '$kMainUrl/coin_purchase';
const String kTopUpCoinList = '$kMainUrl/show_coin_store_listapi';

///----------------------show asset or sendding or puchase  List -------------
const String kAssetListUrl = '$kMainUrl/show_asset_list';
const String kAssetSending = '$kMainUrl/asset_sending';
const String kAssetPurchase = '$kMainUrl/asset_purchase';

///----------------------show backpack List   --------------------------------
const String kBackPackList = '$kMainUrl/back_pack';
const String kBackPackSending = '$kMainUrl/back_pack_sending';
const String kBackPackActive = '$kMainUrl/back_pack_active';
const String kBackPackDeActive = '$kMainUrl/back_pack_deactive';
const String kFrameActive = '$kMainUrl/back_pack_active_list';

///-------------------- show reselar && recharge offer list ------------------
const String kReselerList = '$kMainUrl/reseller_listapi';
const String kRechargeOfferList = '$kMainUrl/show_recharge_offer_listapi';

///-------------------reseller recharge Post Create --------------------------
const String kResellerRecharge = '$kMainUrl/balance_transfer';

///------------------Reseller Coin Trading Post Create -----------------------
const String kResellerCoinTrading = '$kMainUrl/coin_trading';

///-----------------------  Show Notification List ---------------------------
const String kNotificationList = '$kMainUrl/show_notification_listapi';
const String kMarkNotificationRead = '$kMainUrl/notification/mark-as-read';

///-------------------------moment post List show ----------------------------
const String kPostCreateUrl = '$kMainUrl/post_create';
const String kPostListUrl = '$kMainUrl/show_post_list';
const String kFollowCteate = '$kMainUrl/follow_create';
String unFollowUrl(int id) => "$kMainUrl/unfollow/$id";
const String kLikeCreate = '$kMainUrl/like_create';
String unLikeUrl(int id) => "$kMainUrl/dislike/$id";
const String kCommentCreate = '$kMainUrl/comment_create';
const String kCommentList = '$kMainUrl/show_comment_list';

///------------------------ Ranking List Show --------------------------------
const String kRankingList = '$kMainUrl/header_rank';
const String kTopPkHostList = '$kMainUrl/toppk_host';
const String kTopPkHourlyList = '$kMainUrl/toppk_hours';

///---------------------  profile gifted list --------------------------------
String kProfileUpdate({required int id}) => '$kMainUrl/Register_update/$id';

const String kProfileGiftList = '$kMainUrl/auth_user_send_gift';
const String kProfileReceverList = '$kMainUrl/auth_user_Receive_gift';
const String kProfileVisitor = '$kMainUrl/profile_visite';
const String kProfileCombinationList = '$kMainUrl/auth_user_gift_sender_rank';

///---------------------- Auth User Data -------------------------------------
const String kAuthUser = '$kMainUrl/auth_user'; //auth_user

///---------------------- show gifter List-----------------------------------
String kLiveViewersList(int streamId) =>
    "$kMainUrl/livestream/$streamId/viewers";

///---------------------- get total gift coins for livestream------------------
String kGetTotalGiftCoins(int streamId) =>
    "$kMainUrl/livestream/$streamId/total-gift-coins";

///--------------------------- show audio theme list  -------------------------
const String kAudioThemeList = '$kMainUrl/audio_themes';
const String kAudioBackgroundList = '$kMainUrl/audio_background';
const String kAudioThemeSet = '$kMainUrl/user/audio_theme';
String kAudioThemeFace(int userId) => '$kMainUrl/user/$userId/audio_theme';

///--------------------- Livestream start and end time  show ------------------
const String kLivestreamStartTime = "$kMainUrl/livestream_start_time";
const String kLivestreamEndTime = "$kMainUrl/livestream_end_time";

///--------------------------------------------------------------------------
const String kAudioLiveList = '$kMainUrl/audio_livestream_listapi';
const String kRechargeList = '$kMainUrl/show_recharge_offer_listapi';

const String kCoinShopList = '$kMainUrl/show_coin_store_list';

const String kPartyListUrl = '$kMainUrl/show_livestream_list';

const String kVipListUrl = '$kMainUrl/show_vip_vvip_list';

const String kRankingUrl = '$kMainUrl/coins_ranking_list';

const String kPopularUrl = '$kMainUrl/is_online_user';

const String kLikeUrl = '$kMainUrl/like_create';

const String getLiveStreamList = "$kMainUrl/livestreamlist";
const String kLiveStreamListUrl = "$kMainUrl/livestreamlist";

const String kAgencyUrl = '$kMainUrl/agency_create';

const String kAssetCreateUrl = '$kMainUrl/asset_create';

// live streaming staffs sector

const String kAgoraTokenGenerateUrl = '$kMainUrl/agora/token';

// Live Comments
String addComment(
  int streamId,
  int userId,
) =>
    "$kMainUrl/livecomment/$streamId/$userId";

//PK list
const String kPkList = '$kMainUrl/pk_request';

String createLiveStream(int userId) => "$kMainUrl/createlivestream/$userId";
String removeLiveStream(int id) => "$kMainUrl/removelivestream/$id";
String lastPingUpdateUrl(int id) => "$kMainUrl/lastPingUpdate/$id";
// Viewers
String addViewer(int liveStreamId, int viewerId) =>
    "$kMainUrl/addviewer/$liveStreamId/$viewerId";
String removeViewer(int liveStreamId, int viewerId) =>
    "$kMainUrl/removeviewer/$liveStreamId/$viewerId";
String getViewerList(int liveStreamId) => "$kMainUrl/viewerlist/$liveStreamId";
// Calls
const String callLiveStream = "$kMainUrl/calllivestream";
String getCallList(int liveStreamId) => "$kMainUrl/calllist/$liveStreamId";
String acceptCall(int liveStreamId, int userId) =>
    "$kMainUrl/acceptcall/$liveStreamId/$userId";
String acceptPkCall(int liveStreamId, int userId) =>
    "$kMainUrl/acceptcall_pk/$liveStreamId/$userId";
String rejectCall(int liveStreamId, int userId) =>
    "$kMainUrl/rejectcall/$liveStreamId/$userId";
String getAvailableSeats(int livestreamId) =>
    "$kMainUrl/availableseats/$livestreamId";
///------------------------------------------------------------------------
const String kSentGift = "$kMainUrl/giftsr_create_bulk";
const String kGiftList = "$kMainUrl/show_gift_list_list";
//FCM stuffs
const kFCMDeviceCreateUrl = '$kMainUrl/fcm/device-create/';
const kFCMUserTokenUpdateUrl = '$kMainUrl/fcm/token-update/';
const kFCMPeerDeviceUpdateUrl = '$kMainUrl/fcm/peer-device-update/';
const kFCMSinglePushCreate = '$kMainUrl/fcm/single-push-create/';
const kFCMSinglePushForCallingCreate =
    '$kMainUrl/fcm/single-push-for-calling-create/';
// Call Histories
const kCallHistoryListUrl = '$kMainUrl/call-histories/call-history-list/';
const kCallHistoryCreateUrl = '$kMainUrl/call-histories/call-history-create/';
const kNoticsUrl = '$kMainUrl/notifications/notices/';
const kBannersUrl = '$kMainUrl/notifications/banners/';
const kRechargeListUrl = '$kMainUrl/profiles/balance-history/';
const kFreamPersecs = '$kMainUrl/asset_purchase';

//websocket staff
String kCallSepcificUser(int callerId, int receiverId) =>
    "$kMainUrl/rejectcall/$callerId/$receiverId";

//new sagor FireBase Staff

const String kSentNotiSpecificUser = '$kMainUrl/sentnotispecificuser';
String sentNotiSpecificUser(String deviceToken) =>
    '$kSentNotiSpecificUser/$deviceToken';
const String kGetAndUpdateDeviceToken = '$kMainUrl/getandupatedevicetoken';
String getAndUpdateDeviceToken(
        {required int userId, required String deviceToken}) =>
    '$kGetAndUpdateDeviceToken/$userId/$deviceToken';
const String kCallSpecificUser = '$kMainUrl/callspecificuser';
String callSpecificUser(
        {required int callerId,
        required int receiverId,
        required String type}) =>
    '$kCallSpecificUser/$callerId/$receiverId/$type';
const String kUpdateCallStatus = '$kMainUrl/updatecallstatus';
String updateCallStatus(int callId, String status) =>
    '$kUpdateCallStatus/$callId/$status';
// Audio/Video Toggle APIs
String kAudioToggleUrl(int streamId, int userId) =>
    '$kMainUrl/livestream/$streamId/audio_toggle/$userId';
String kVideoToggleUrl(int streamId, int userId) =>
    '$kMainUrl/livestream/$streamId/video_toggle/$userId';
String kKickOutUrl(int streamId, int userId) =>
    '$kMainUrl/livestream/$streamId/kickout/$userId';
String kCheckCanJoinUrl(int streamId, int userId) =>
    '$kMainUrl/livestream/$streamId/check-can-join/$userId';
String getAvailableSeatUrl(int streamId) =>
    '$kMainUrl/livestream/$streamId/availableseats';


// Red Packet API Endpoints
String get kSendRedPacketUrl => '$kMainUrl/red-packets/send';
String kCollectRedPacketUrl(int redPacketId) =>
    '$kMainUrl/red-packets/$redPacketId/collect';
String kRefundRedPacketUrl(int redPacketId) =>
    '$kMainUrl/red-packets/$redPacketId/refund';
String kGetRedPacketsForLivestreamUrl(int livestreamId) =>
    '$kMainUrl/red-packets/livestream/$livestreamId';
String get kGetUserRedPacketHistoryUrl => '$kMainUrl/red-packets/user/history';

// // Greedy Game API Endpoints
// const String kGreedyWinnerList = '$kMainUrl/greedy_winner_list';
// const String kGreedyGameStats = '$kMainUrl/greedy_game_stats';
// const String kGreedyPlaceBet = '$kMainUrl/greedy_place_bet';
// const String kGreedyUserHistory = '$kMainUrl/greedy_user_history';
// const String kGreedyStartGame = '$kMainUrl/greedy_start_game';
// const String kGreedyEndGame = '$kMainUrl/greedy_end_game';
// const String kGreedyBroadcastTimer = '$kMainUrl/greedy_broadcast_timer';
// const String kGreedyCurrentStatus = '$kMainUrl/greedy_current_status';

// // WebSocket Constants for Greedy Game
// const String kGreedyGameSocket = kWsUrl; // Uses the same WebSocket URL
// const String kSentDataToGreedySocket = '$kMainUrl/greedy_send_data';
// const String kGreedyBalanceMinus = '$kMainUrl/greedy_balance_minus';
// const String kGreedyBalancePlus = '$kMainUrl/greedy_balance_plus';

///---------------- Fruit Game endpoints ------------------------------------
const String kFruitGameJoinUrl = '$kMainUrl/fruitgame/join';
const String kFruitGameLeaveUrl = '$kMainUrl/fruitgame/leave';
const String kFruitGameBetUrl = '$kMainUrl/fruitgame/bet';
const String kFruitGameEndRoundUrl = '$kMainUrl/fruitgame/end-round';
const String kFruitGameStatusUrl = '$kMainUrl/fruitgame/status';
const String kUserCoinsUrl = '$kMainUrl/userCoins';
/// ---------------- User Coins -------------------------------------


// set Guardian
String kSetGuardian({required int streamId, required int userId}) =>
    '$kMainUrl/livestream/$streamId/guardian/$userId';
String kRemoveGuardian({required int streamId, required int userId}) =>
    '$kMainUrl/livestream/$streamId/guardian/$userId';
String kisGuardian({required int streamId, required int userId}) =>
    '$kMainUrl/livestream/$streamId/isguardian/$userId';
String kGuardianList({required int streamId}) =>
    '$kMainUrl/livestream/$streamId/guardian';
// Live Record
const String kCurrentMonthLiveRecord = '$kMainUrl/currentMonthLiveRecord';
const String kDateWiseFilterLiveRecord = '$kMainUrl/dateWiseFilterLiveRecord';
const String kSessionWiseLiveRecord = '$kMainUrl/seasionWiseLiveRecord';
const String kLiveReword = '$kMainUrl/reword_coin';
//----------app version update-----------
const String kAppVersionUpdate = '$kMainUrl/apk_vertion_list';

///-------agora token generate api---------------////
// const String kAgoraTokenGenerateBroadcaster =
//     'http://appidtoken.meetliveapps.org/api/agora/token/broadcaster';
// const String kAgoraTokenGenerateAudience =
//     'http://appidtoken.meetliveapps.org/api/agora/token/audience';
// String kAgoraTokenGenerateErrorApi({required int applicationId}) =>
//     'http://appidtoken.meetliveapps.org/api/agora/app/$applicationId/not-working';

// const String kAgoraTokenGenerateBroadcaster =
//     'https://srv1634476.hstgr.cloud/api/agora/token/broadcaster';
// const String kAgoraTokenGenerateAudience =
//     'https://srv1634476.hstgr.cloud/api/agora/token/audience';
// String kAgoraTokenGenerateErrorApi({required int applicationId}) =>
//     'https://srv1634476.hstgr.cloud/api/agora/app/$applicationId/not-working';


const String coinPersentense = '$kMainUrl/trade_setting';
const String kAgoraTokenGenerateBroadcaster =
    'https://app-id-token.dev.sheikhit.net/api/agora/token/broadcaster';
const String kAgoraTokenGenerateAudience =
    'https://app-id-token.dev.sheikhit.net/api/agora/token/audience';
String kAgoraTokenGenerateErrorApi({required int applicationId}) =>
    'https://app-id-token.dev.sheikhit.net/api/agora/app/$applicationId/not-working';

