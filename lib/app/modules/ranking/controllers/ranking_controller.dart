import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../apis/api_endpoints.dart';
import '../../../../constants/constants.dart';

class RankingController extends GetxController {
  //TODO: Implement RankingController

  // ✅ Moved here
  var selectedCountry = Rx<Country>(
    Country(
      countryCode: 'BD',
      phoneCode: '880',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'Bangladesh',
      example: '',
      displayName: 'Bangladesh',
      displayNameNoCountryCode: 'Bangladesh',
      e164Key: '',
    ),
  );

  final isFollow = false.obs;

  final isLoading = false.obs;

  final _dio = Dio();

  final rankingList = [].obs;

  Future getRankingList() async {
    final data = await _dio.get(kRankingUrl);
    rankingList.value = data.data;
  }

  ///------------------------- Ranking List show -------------------
  final senderRanking = [].obs;
  final receiverRanking = [].obs;
  final agencyRanking = [].obs;

  Future showRankingList() async {
    final response = await _dio.get(
      kRankingList,
      options: Options(
        headers: {
          'Authorization':
              'Bearer ${authController.userProfile.value.token}', // Correct Bearer Token usage
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;

      senderRanking.value = data['sender'] ?? [];
      receiverRanking.value = data['receiver'] ?? [];
      agencyRanking.value = data['agency'] ?? [];
    }
  }

  ///---------------- top pk host ranking list ------------------------

  final dalyRanking = [].obs;
  final weeklyRanking = [].obs;
  final monthlyRanking = [].obs;

  Future showTopPkHost() async {
    final response = await _dio.get(
      kTopPkHostList,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      print('topPk host data ${response.data}');
      dalyRanking.value = data['daily'] ?? [];
      weeklyRanking.value = data['weekly'] ?? [];
      monthlyRanking.value = data['monthly'] ?? [];
    }
  }

  ///----------------- top Hourly Pk Ranking ---------
  final hourlyRankingList = [].obs;
  Future showTopHourly() async {
    final response = await _dio.get(
      kTopPkHourlyList,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      print('topPk host data ${response.data}');
      hourlyRankingList.value = data['daily'] ?? [];
      // weeklyRanking.value = data['weekly'] ?? [];
    }
  }
}
