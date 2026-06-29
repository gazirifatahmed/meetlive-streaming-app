class Asset {
  num? id;
  String? name;
  String? asset;
  String? price;
  String? type;

  Asset({this.id, this.name, this.asset, this.price, this.type});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "asset": asset,
      "price": price,
      "type": type,
    };
  }

  Asset.fromJson(dynamic json) {
    id = json["id"];
    name = json["name"]?.toString();
    asset = json["asset"]?.toString();
    price = json["price"]?.toString();
    type = json["type"]?.toString();
  }
}

class AssetHistories {
  num? id;
  num? userId;
  num? assetId;
  String? type;
  String? status;
  Asset? asset;

  AssetHistories({
    this.id,
    this.userId,
    this.assetId,
    this.type,
    this.status,
    this.asset,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "asset_id": assetId,
      "type": type,
      "status": status,
      "asset": asset?.toJson(),
    };
  }

  AssetHistories.fromJson(dynamic json) {
    id = json["id"];
    userId = json["user_id"];
    assetId = json["asset_id"];
    type = json["type"]?.toString();
    status = json["status"]?.toString();
    asset = json["asset"] != null ? Asset.fromJson(json["asset"]) : null;
  }
}

class EntryHistories {
  num? id;
  num? userId;
  num? assetId;
  String? type;
  String? status;
  Asset? asset;

  EntryHistories({
    this.id,
    this.userId,
    this.assetId,
    this.type,
    this.status,
    this.asset,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "asset_id": assetId,
      "type": type,
      "status": status,
      "asset": asset?.toJson(),
    };
  }

  EntryHistories.fromJson(dynamic json) {
    id = json["id"];
    userId = json["user_id"];
    assetId = json["asset_id"];
    type = json["type"]?.toString();
    status = json["status"]?.toString();
    asset = json["asset"] != null ? Asset.fromJson(json["asset"]) : null;
  }
}

class VipHistories {
  num? id;
  num? userId;
  num? assetId;
  String? type;
  String? status;
  Asset? asset;

  VipHistories({
    this.id,
    this.userId,
    this.assetId,
    this.type,
    this.status,
    this.asset,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "asset_id": assetId,
      "type": type,
      "status": status,
      "asset": asset?.toJson(),
    };
  }

  VipHistories.fromJson(dynamic json) {
    id = json["id"];
    userId = json["user_id"];
    assetId = json["asset_id"];
    type = json["type"]?.toString();
    status = json["status"]?.toString();
    asset = json["asset"] != null ? Asset.fromJson(json["asset"]) : null;
  }
}

class User {
  num? id;
  num? userId;
  String? agencyId;
  String? hostAgencyId;
  String? name;
  String? level;
  String? email;
  String? googleId;
  String? phone;
  String? whatsappNumber;
  String? address;
  String? gender;
  String? dateofbirth;
  String? language;
  String? userType;
  String? agencyType;
  String? reselerType;
  String? hostType;
  String? hostPosition;
  String? designation;
  String? balance;
  String? coins;
  String? callRate;
  String? earnedCoins;
  String? giftsCoins;
  String? profileImage;
  String? country;
  String? emailVerifiedAt;
  String? coverImages;
  String? profileLocked;
  String? status;
  String? isOnline;
  String? callStatus;
  String? refferCode;
  String? otp;
  String? updatedAt;
  num? audioThemeId;
  String? levelImage;
  num? totalFollowers;
  num? totalFollowing;

  User({
    this.id,
    this.userId,
    this.agencyId,
    this.hostAgencyId,
    this.name,
    this.level,
    this.email,
    this.googleId,
    this.phone,
    this.whatsappNumber,
    this.address,
    this.gender,
    this.dateofbirth,
    this.language,
    this.userType,
    this.agencyType,
    this.reselerType,
    this.hostType,
    this.hostPosition,
    this.designation,
    this.balance,
    this.coins,
    this.callRate,
    this.earnedCoins,
    this.giftsCoins,
    this.profileImage,
    this.country,
    this.emailVerifiedAt,
    this.coverImages,
    this.profileLocked,
    this.status,
    this.isOnline,
    this.callStatus,
    this.refferCode,
    this.otp,
    this.updatedAt,
    this.audioThemeId,
    this.levelImage,
    this.totalFollowers,
    this.totalFollowing,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "agency_id": agencyId,
      "host_agency_id": hostAgencyId,
      "name": name,
      "level": level,
      "email": email,
      "google_id": googleId,
      "phone": phone,
      "whatsapp_number": whatsappNumber,
      "address": address,
      "gender": gender,
      "dateofbirth": dateofbirth,
      "language": language,
      "user_type": userType,
      "agency_type": agencyType,
      "reseler_type": reselerType,
      "host_type": hostType,
      "host_position": hostPosition,
      "designation": designation,
      "balance": balance,
      "coins": coins,
      "call_rate": callRate,
      "earned_coins": earnedCoins,
      "gifts_coins": giftsCoins,
      "profile_image": profileImage,
      "country": country,
      "email_verified_at": emailVerifiedAt,
      "cover_images": coverImages,
      "profile_locked": profileLocked,
      "status": status,
      "is_online": isOnline,
      "call_status": callStatus,
      "reffer_code": refferCode,
      "otp": otp,
      "updated_at": updatedAt,
      "audio_theme_id": audioThemeId,
      "level_image": levelImage,
      "total_followers": totalFollowers,
      "total_following": totalFollowing,
    };
  }

  User.fromJson(dynamic json) {
    id = json["id"];
    userId = json["user_id"];
    agencyId = json["agency_id"]?.toString();
    hostAgencyId = json["host_agency_id"]?.toString();
    name = json["name"]?.toString();
    level = json["level"]?.toString();
    email = json["email"]?.toString();
    googleId = json["google_id"]?.toString();
    phone = json["phone"]?.toString();
    whatsappNumber = json["whatsapp_number"]?.toString();
    address = json["address"]?.toString();
    gender = json["gender"]?.toString();
    dateofbirth = json["dateofbirth"]?.toString();
    language = json["language"]?.toString();
    userType = json["user_type"]?.toString();
    agencyType = json["agency_type"]?.toString();
    reselerType = json["reseler_type"]?.toString();
    hostType = json["host_type"]?.toString();
    hostPosition = json["host_position"]?.toString();
    designation = json["designation"]?.toString();
    balance = json["balance"]?.toString();
    coins = json["coins"]?.toString();
    callRate = json["call_rate"]?.toString();
    earnedCoins = json["earned_coins"]?.toString();
    giftsCoins = json["gifts_coins"]?.toString();
    profileImage = json["profile_image"]?.toString();
    country = json["country"]?.toString();
    emailVerifiedAt = json["email_verified_at"]?.toString();
    coverImages = json["cover_images"]?.toString();
    profileLocked = json["profile_locked"]?.toString();
    status = json["status"]?.toString();
    isOnline = json["is_online"]?.toString();
    callStatus = json["call_status"]?.toString();
    refferCode = json["reffer_code"]?.toString();
    otp = json["otp"]?.toString();
    updatedAt = json["updated_at"]?.toString();
    audioThemeId = json["audio_theme_id"];
    levelImage = json["level_image"]?.toString();
  }
}

class UserProfile {
  bool? success;
  String? message;
  String? token;
  User? user;

  num? totalFollowers;
  num? totalFollowing;

  AssetHistories? assetHistories;
  EntryHistories? entryHistories;
  VipHistories? vipHistories;

  UserProfile({
    this.success,
    this.message,
    this.token,
    this.user,
    this.totalFollowers,
    this.totalFollowing,
    this.assetHistories,
    this.entryHistories,
    this.vipHistories,
  });

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "token": token,
      "user": user?.toJson(),
      "total_followers": totalFollowers,
      "total_following": totalFollowing,
      "asset_histories": assetHistories?.toJson(),
      "entry_histories": entryHistories?.toJson(),
      "vip_histories": vipHistories?.toJson(),
    };
  }

  UserProfile.fromJson(dynamic json) {
    success = json["success"];
    message = json["message"]?.toString();
    token = json["token"]?.toString();

    user = json["user"] != null ? User.fromJson(json["user"]) : null;

    totalFollowers = json["total_followers"];
    totalFollowing = json["total_following"];

    assetHistories = json["asset_histories"] != null
        ? AssetHistories.fromJson(json["asset_histories"])
        : null;

    entryHistories = json["entry_histories"] != null
        ? EntryHistories.fromJson(json["entry_histories"])
        : null;

    vipHistories = json["vip_histories"] != null
        ? VipHistories.fromJson(json["vip_histories"])
        : null;
  }
}