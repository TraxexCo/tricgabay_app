// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get serverConnectionRequired =>
      'Kailangan ng koneksyon sa server para rito. Suriin ang internet at mag-sign in muli.';

  @override
  String adminGcashDisputesOpen(int count) {
    return '$count pinagtatalunang pamasahe sa GCash';
  }

  @override
  String get outstandingFareBlocked =>
      'May hindi pa nababayarang pamasahe ka mula sa naunang biyahe. Bayaran muna ang drayber o kausapin ang suporta bago muling magpareserba.';

  @override
  String get outstandingFareTitle => 'Hindi pa bayad na pamasahe';

  @override
  String get outstandingFareAction => 'Buksan ang biyaheng hindi pa bayad';

  @override
  String get gcashReferenceUsed =>
      'Nagamit na ang GCash reference number na ito sa ibang biyahe.';

  @override
  String get gcashProofRequired =>
      'Sinabi ng drayber na hindi pa niya natatanggap ang bayad. Ipadala na lang ang resibo at reference number.';

  @override
  String get onlinePaymentUnavailable =>
      'Hindi na available ang online card payment. Pumili ng cash o GCash.';

  @override
  String get gcashQrTitle => 'GCash QR ng drayber';

  @override
  String get gcashSaveQr => 'I-share o i-save ang QR';

  @override
  String get gcashQrHint =>
      'Sa GCash, pindutin ang Scan QR, tapos Upload QR, at piliin ang larawang ito. Puwede ring i-scan ang QR sa traysikel.';

  @override
  String get gcashQrMissing =>
      'Wala pang QR code ang drayber na ito. Gamitin ang numero sa ibaba.';

  @override
  String get gcashUploadQr => 'I-upload ang GCash QR';

  @override
  String get gcashReplaceQr => 'Palitan ang QR';

  @override
  String get gcashQrSaved => 'Nai-save ang QR code';

  @override
  String get gcashQrDescription =>
      'Makikita lang ng turista ang QR mo kapag binabayaran ka para sa natapos na biyahe.';

  @override
  String get gcashProofTitle => 'Magpadala ng patunay ng bayad';

  @override
  String get gcashProofBody =>
      'Hindi pa natatanggap ng drayber ang bayad. Ilakip ang screenshot ng resibo sa GCash at ang reference number.';

  @override
  String get gcashChooseReceipt => 'Pumili ng screenshot ng resibo';

  @override
  String get gcashReceiptChosen => 'Napili na ang resibo';

  @override
  String get gcashReferenceRequired => 'GCash reference number';

  @override
  String get gcashSubmitProof => 'Ipadala ang patunay';

  @override
  String get gcashProofSent => 'Naipadala ang patunay sa drayber';

  @override
  String get gcashViewReceipt => 'Tingnan ang resibo';

  @override
  String get gcashAskAdmin => 'Ipaubaya sa admin';

  @override
  String get gcashAskAdminBody =>
      'Gamitin lang ito kung hindi ninyo maaayos nang magkasama. Titingnan ng admin ang resibo at magpapasya.';

  @override
  String get gcashAdminNote => 'Tala para sa admin (opsyonal)';

  @override
  String get gcashSentToAdmin => 'Ipinadala sa admin para suriin';

  @override
  String get gcashEscalatedNotice =>
      'Sinusuri ng admin ang bayad na ito. Puwede pa rin ninyong ayusin nang magkasama.';

  @override
  String get gcashRulingPaid => 'Pasya ng admin: bayad na';

  @override
  String get gcashRulingNotPaid => 'Pasya ng admin: hindi bayad';

  @override
  String get gcashRulingWaived => 'Pasya ng admin: hindi na sisingilin';

  @override
  String get gcashReferenceLabel => 'GCash reference';

  @override
  String get adminGcashDisputes => 'Mga pagtutol sa GCash';

  @override
  String get adminGcashDisputesEmpty => 'Walang bukas na pagtutol sa GCash.';

  @override
  String get adminDisputeEscalated => 'Kailangan ng pasya';

  @override
  String get adminDisputeWaiting => 'Hinihintay ang turista at drayber';

  @override
  String get adminDisputeUnsettled =>
      'Hindi bayad ang pasya · hindi pa naaayos';

  @override
  String get adminRulePaid => 'Ipasya: nagbayad ang turista';

  @override
  String get adminRuleNotPaid => 'Ipasya: hindi nagbayad ang turista';

  @override
  String get adminWaiveFare => 'Huwag nang singilin';

  @override
  String get adminRulingReason => 'Dahilan ng iyong pasya';

  @override
  String get adminNoReceipt => 'Wala pang naipadalang resibo.';

  @override
  String get adminDriverNote => 'Tala ng drayber';

  @override
  String get adminEscalationNote => 'Tala sa pag-akyat sa admin';

  @override
  String get adminDecisionSaved => 'Nai-save ang pasya';

  @override
  String get gcashSendToDriver => 'GCash (ipadala sa drayber)';

  @override
  String get gcashAfterTrip =>
      'Ipapadala mo ang pamasahe sa GCash ng iyong drayber pagkatapos ng biyahe.';

  @override
  String get gcashCompleteTrip => 'Tapusin ang biyahe';

  @override
  String get gcashDetails => 'Mga detalye ng bayad sa GCash';

  @override
  String get gcashNumber => 'Numero ng GCash';

  @override
  String get gcashConfirmNumber => 'Ilagay muli ang numero ng GCash';

  @override
  String get gcashAccountName => 'Nakarehistrong pangalan sa GCash';

  @override
  String get gcashActive => 'Tumanggap ng bayad sa GCash';

  @override
  String get gcashInactive => 'Naka-off ang pagbabayad sa GCash';

  @override
  String get gcashNotConfigured =>
      'Wala pang idinagdag na detalye sa GCash ang drayber na ito.';

  @override
  String get gcashVisibility =>
      'Makikita ng mga turista ang numero at pangalang ito kapag nagbabayad sa iyo sa GCash.';

  @override
  String get gcashInvalidNumber =>
      'Gumamit ng numerong nasa format na 09XXXXXXXXX o +639XXXXXXXXX.';

  @override
  String get gcashNumberMismatch =>
      'Dapat magkapareho ang mga numero ng GCash.';

  @override
  String get gcashInvalidName =>
      'Ilagay ang pangalan ng account gamit ang 2 hanggang 120 character.';

  @override
  String get gcashCheckName =>
      'Bago magpadala, tiyaking tugma ang pangalang ipinapakita sa GCash.';

  @override
  String get gcashOpen => 'Buksan ang GCash';

  @override
  String get gcashLaunchFailed =>
      'Walang GCash o hindi ito mabuksan. Maaari mo pa ring kopyahin ang numero at halaga.';

  @override
  String get gcashCopyNumber => 'Kopyahin ang numero';

  @override
  String get gcashCopyAmount => 'Kopyahin ang halaga';

  @override
  String get gcashNumberCopied => 'Nakopya ang numero';

  @override
  String get gcashAmountCopied => 'Nakopya ang halaga';

  @override
  String get gcashSent => 'Naipadala ko na ang bayad';

  @override
  String get gcashReference => 'Numero ng reference sa GCash (opsyonal)';

  @override
  String get gcashInvalidReference =>
      'Gumamit ng 8 hanggang 20 titik o numero para sa reference number.';

  @override
  String get gcashPayCash => 'Magbayad na lang ng cash';

  @override
  String get gcashNotSetUp =>
      'Wala pang naka-set up na GCash ang iyong drayber. Magbayad na lang ng cash.';

  @override
  String get gcashAwaitingDriver => 'Hinihintay ang kumpirmasyon ng drayber';

  @override
  String get gcashAwaitingYour => 'Hinihintay ang iyong kumpirmasyon';

  @override
  String get gcashDisputed => 'May pagtutol sa bayad sa GCash';

  @override
  String get gcashDisputeMessage =>
      'Hindi pa natatanggap ng drayber ang bayad. Suriin ang resibo at reference number sa GCash, o magbayad ng cash.';

  @override
  String get gcashSlide => 'I-slide upang kumpirmahing natanggap ang bayad';

  @override
  String get gcashDriverConfirm => 'Kumpirmahing natanggap ang bayad';

  @override
  String get gcashNotReceived => 'Hindi pa natatanggap';

  @override
  String get gcashDisputeNote => 'Maikling tala (opsyonal)';

  @override
  String get gcashPaidByDriver => 'Kinumpirma ng drayber ang bayad';

  @override
  String get gcashActionFailed =>
      'Hindi natapos ang aksyon sa GCash. I-refresh ang reserbasyon at subukang muli.';

  @override
  String get gcashSettingsSaved => 'Na-save ang mga detalye ng GCash';

  @override
  String get gcashCashWarning =>
      'Kung nakapagpadala ka na, suriin muna ang resibo sa GCash kasama ang drayber bago magbayad ng cash.';

  @override
  String get gcashFareToPay => 'Pamasaheng babayaran';

  @override
  String get gcashCheckWallet =>
      'Tiyaking pumasok sa iyong GCash ang pamasahe bago kumpirmahin.';

  @override
  String get gcashAmountReceived => 'Natanggap na pamasahe sa GCash';

  @override
  String get gcashConfirmedFares => 'Mga kinumpirmang pamasahe';

  @override
  String get gcashConfirmedFaresOverTime =>
      'Mga kinumpirmang pamasahe sa paglipas ng panahon';

  @override
  String get loadedBookingTotals =>
      'Mga reserbasyong na-load sa app lamang ang kasama sa mga bilang at halaga.';

  @override
  String get gcashEarningsExplanation =>
      'Kasama ang mga kinumpirmang direktang bayad sa GCash. Hindi kasama ang mga halagang sinusuri pa.';

  @override
  String get abc1234 => 'ABC 1234';

  @override
  String get abc1234AccreditedDriver => 'ABC 1234 • Akreditadong drayber';

  @override
  String get about => 'Tungkol dito';

  @override
  String get accept => 'Tanggapin';

  @override
  String get acceptAndContinue => 'Tanggapin at magpatuloy';

  @override
  String get acceptAssistanceRequests =>
      'Tumanggap ng mga kahilingan para sa tulong';

  @override
  String get accepted => 'Tinanggap';

  @override
  String get acceptTheCurrentPrivacyNoticeBeforeSubmitting =>
      'Tanggapin ang kasalukuyang abiso sa privacy bago magsumite.';

  @override
  String get accessibilityOrAssistanceNeeds =>
      'Pangangailangan sa aksesibilidad o tulong';

  @override
  String get account => 'Account';

  @override
  String get accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain =>
      'Hindi ma-access ang account. Suriin ang mga detalye at subukan muli.';

  @override
  String get accountCreatedConfirmYourEmailThenSignIn =>
      'Nagawa na ang account. Kumpirmahin ang email mo bago mag-login.';

  @override
  String get accreditationVerified => 'Beripikado ang akreditasyon';

  @override
  String get aConfiguredServerAndAdministratorAccountAreRequired =>
      'Kailangan ang naka-configure na server at account ng administrador.';

  @override
  String get activate => 'I-activate';

  @override
  String get activateTourist => 'I-activate ang Turista';

  @override
  String activateValue(String value) {
    return 'I-activate si $value';
  }

  @override
  String get active => 'Aktibo';

  @override
  String get activeTrip => 'Kasalukuyang biyahe';

  @override
  String get activeTripRoute => 'Ruta ng kasalukuyang biyahe';

  @override
  String get actNow => 'Kumilos ngayon';

  @override
  String get addAStatementToThisCase => 'Magdagdag ng salaysay sa kasong ito';

  @override
  String get addedToItinerary => 'Naidagdag sa itineraryo!';

  @override
  String get addedToYourItinerary => 'Naidagdag sa iyong itineraryo!';

  @override
  String get address => 'Address';

  @override
  String get addressDetails => 'Mga detalye ng address';

  @override
  String get addressMatchesPin => 'Tugma ang address sa pin';

  @override
  String get addToTrip => '+ Idagdag sa biyahe';

  @override
  String get addToTripLabel => 'Idagdag sa biyahe';

  @override
  String get addTouristSpot => 'Magdagdag ng Pasyalan';

  @override
  String get addYourStatement => 'Idagdag ang iyong salaysay';

  @override
  String get aDestinationIsNoLongerAvailableUpdateYourItinerary =>
      'Hindi na available ang isang destinasyon. I-update ang iyong itineraryo.';

  @override
  String get adjustPin => 'Ayusin ang pin';

  @override
  String get administratorUpdatedFixedFares =>
      'Na-update ng administrador ang mga takdang pamasahe.';

  @override
  String get adminPasswordIsRequired => 'Kailangan ang password ng admin';

  @override
  String get adminReviewPaymentOnHold =>
      'Sinusuri ng admin · nakahold ang bayad';

  @override
  String
  get affectedTouristsAndAssignedDriversWillBeNotifiedExistingBookingsKeepAnAudit =>
      'Aabisuhan ang mga apektadong turista at drayber. Magkakaroon ng tala ng pagsusuri ang mga kasalukuyang reserbasyon.';

  @override
  String get agreeAndContinue => 'Sumang-ayon at magpatuloy';

  @override
  String get agreedFare => 'Napagkasunduang pamasahe';

  @override
  String get agreedFixedFare => 'Napagkasunduang nakapirming pamasahe';

  @override
  String
  agreedMaximumStopsConfirmedByTheTouristTheSuggestedProratedAmountIsAValue(
    String value,
    String secondValue,
    String thirdValue,
  ) {
    return 'Napagkasunduang pinakamataas na singil: $value. Kinumpirma ng turista ang $secondValue/$thirdValue hintuan. Panimulang mungkahi lamang ang proporsiyonal na halaga. Suriin ang mga salaysay, kaligtasan at serbisyong naibigay. Walang multa o dagdag-singil.';
  }

  @override
  String get agreedPolicy => 'Napagkasunduang patakaran';

  @override
  String agreedValue(String value) {
    return 'Napagkasunduan\n₱$value';
  }

  @override
  String get all => 'Lahat';

  @override
  String get allowLocationAccessInAndroidSettings =>
      'Payagan ang access sa lokasyon sa mga setting ng Android.';

  @override
  String get allowMatchingForTouristsWithMobilityOrBoardingNeeds =>
      'Payagang maitugma sa mga turistang nangangailangan ng tulong sa pagkilos o pagsakay.';

  @override
  String get allowOptionalCrashDiagnostics =>
      'Payagan ang opsiyonal na pagsusuri ng pag-crash';

  @override
  String get allStopsAreConfirmedOpenTripControlsToFinish =>
      'Nakumpirma na ang lahat ng hintuan. Buksan ang mga kontrol ng biyahe upang tapusin.';

  @override
  String get alreadyHaveAnAccount => 'May account ka na ba?';

  @override
  String get aNearbyTouristIsLookingForADriver =>
      'Naghahanap ng drayber ang isang kalapit na turista.';

  @override
  String get announcementSentSuccessfully =>
      'Matagumpay na naipadala ang anunsiyo';

  @override
  String get anotherAccountIsAlreadySignedInSignOutBeforeRegisteringADriver =>
      'May ibang account na naka-sign in. Mag-sign out muna bago magparehistro ng drayber.';

  @override
  String get aPackageStopIsUnavailablePleaseChooseAnotherRoute =>
      'Hindi available ang isang hintuan sa package. Pumili ng ibang ruta.';

  @override
  String appDriverIsOnline(String brandName) {
    return 'Naka-online ang drayber ng $brandName';
  }

  @override
  String get applicationPending => 'Naghihintay ang aplikasyon';

  @override
  String get applicationRejected => 'Tinanggihan ang aplikasyon.';

  @override
  String get applicationSubmittedForAdministratorReview =>
      'Naipasa na ang aplikasyon para sa pagsusuri ng administrador.';

  @override
  String appManagementSystem(String brandName) {
    return 'Sistema ng Pamamahala ng $brandName';
  }

  @override
  String appName(String brandName) {
    return '$brandName';
  }

  @override
  String appReportValue(String value, String brandName) {
    return 'Ulat ng $brandName para sa $value';
  }

  @override
  String get approveAndEnableMatching =>
      'Aprubahan at paganahin ang pagtutugma';

  @override
  String get approved => 'Aprubado';

  @override
  String get approvedServiceArea => 'Aprubadong lugar ng serbisyo';

  @override
  String get approveRouteChange => 'Aprubahan ang pagbabago ng ruta';

  @override
  String get apr => 'Abr';

  @override
  String get aPrePickupReviewCannotIncreaseTheSnapshottedCancellationCharge =>
      'Hindi maaaring taasan ng pagsusuri bago ang pagsakay ang naitalang singil sa pagkansela.';

  @override
  String
  get aPreviousBookingRequestIsAwaitingConfirmationReconnectAndOpenTripsBeforeChanging =>
      'Naghihintay ng kumpirmasyon ang naunang reserbasyon. Kumonekta muli at buksan ang Mga Biyahe bago baguhin ang kahilingan.';

  @override
  String get areaName => 'Pangalan ng lugar';

  @override
  String get areaUnverified => 'Hindi pa beripikado ang lugar';

  @override
  String areCurrentlyOnATripValue(String value) {
    return '$value ang kasalukuyang bumibiyahe';
  }

  @override
  String get areYouInAnEmergency => 'May emergency ka ba?';

  @override
  String get areYouSureYouWantToLogOut =>
      'Sigurado ka bang gusto mong mag-log out?';

  @override
  String areYouSureYouWantToLogOutOfApp(String brandName) {
    return 'Sigurado ka bang gusto mong mag-log out sa $brandName?';
  }

  @override
  String arrivalReportedValue(String value) {
    return 'Iniulat ang pagdating: $value.';
  }

  @override
  String get askTheTouristForTheCorrectPickupCodeOnceTheyAreOnBoard =>
      'Hingin ang tamang code sa turista kapag nakasakay na siya.';

  @override
  String get askTheTouristForTheirCodeAfterTheyAreSafelyOnBoard =>
      'Hingin ang code ng turista kapag ligtas na siyang nakasakay.';

  @override
  String get assignedDriver => 'Nakatalagang drayber';

  @override
  String get attachBothRequiredDriverDocuments =>
      'Ilakip ang dalawang kailangang dokumento ng drayber.';

  @override
  String attachedValue(String value) {
    return 'Nakalakip ang $value';
  }

  @override
  String get attraction => 'Pasyalan';

  @override
  String attractionAndFareInformationIsSynchronizedWithApp(String brandName) {
    return 'Sinasabay sa $brandName ang impormasyon sa mga pasyalan at pamasahe.';
  }

  @override
  String get audience => 'Mga tatanggap';

  @override
  String audienceValue(String value) {
    return 'Mga tatanggap: $value';
  }

  @override
  String get auditedRouteChangesRequireTheConfiguredServer =>
      'Kailangan ang naka-configure na server para sa naitalang pagbabago ng ruta.';

  @override
  String get aug => 'Ago';

  @override
  String get availability => 'Availability';

  @override
  String avatarCleanupPendingForObjectValue(String value) {
    return 'Naghihintay ang paglilinis ng larawan ng profile para sa object na $value';
  }

  @override
  String get avatarObjectVersionIsInvalid =>
      'Hindi wasto ang bersiyon ng larawan ng profile.';

  @override
  String get avatarOwnerIsInvalid =>
      'Hindi wasto ang may-ari ng larawan ng profile.';

  @override
  String get awaitingBothCashConfirmations =>
      'Hinihintay ang kumpirmasyon ng parehong panig sa cash';

  @override
  String awaitingPaymentValue(String value) {
    return 'Hinihintay na bayad: ₱$value';
  }

  @override
  String get back => 'Bumalik';

  @override
  String get backToExplore => 'Bumalik sa pag-explore';

  @override
  String get backToLogin => 'Bumalik sa Pag-login';

  @override
  String get barangay => 'Barangay';

  @override
  String get blocked => 'Hinaharang';

  @override
  String get blockedCheckoutExpiry => 'Nakaharang na pag-expire ng checkout';

  @override
  String get bongaMayor => 'Bonga mayor';

  @override
  String get bongaMenor => 'Bonga menor';

  @override
  String get bookATourToGetStarted =>
      'Magpareserba ng paglilibot upang magsimula!';

  @override
  String get bookATricycle => 'magpareserba ng traysikel';

  @override
  String bookForValue(String value) {
    return 'Magpareserba sa halagang ₱$value';
  }

  @override
  String get booking => 'Reserbasyon';

  @override
  String get bookingAndSystemUpdates => 'Mga update sa reserbasyon at sistema';

  @override
  String get bookingDetailsCancel => 'Detalye ng reserbasyon / kanselahin';

  @override
  String get bookingDriverPaymentAndSafetyUpdates =>
      'Mga update sa reserbasyon, drayber, pagbabayad at kaligtasan';

  @override
  String get bookingHistory => 'Kasaysayan ng reserbasyon';

  @override
  String get bookingNotFoundForThisAccount =>
      'Walang nakitang reserbasyon para sa account na ito.';

  @override
  String get bookings => 'Mga reserbasyon';

  @override
  String get bookingSessionChanged => 'Nagbago ang session ng reserbasyon.';

  @override
  String get bookingsPaymentReviews => 'Mga reserbasyon at pagsusuri ng bayad';

  @override
  String get bookingsToday => 'Mga reserbasyon ngayon';

  @override
  String bookingValue(String value) {
    return 'reserbasyon $value';
  }

  @override
  String get bookNow => 'Magpareserba ngayon';

  @override
  String get bookThisTour => 'Ipareserba ang paglilibot na ito';

  @override
  String get bothDriverDocumentsAreRequired =>
      'Kailangan ang parehong dokumento ng drayber.';

  @override
  String get bothDriverDocumentsMustBeValidImagesUnder5Mb =>
      'Dapat wastong larawan na wala pang 5 MB ang parehong dokumento ng drayber.';

  @override
  String get brandMark => 'T';

  @override
  String get broadcastAMessage => 'Mag-broadcast ng Mensahe';

  @override
  String get bugReport => 'Ulat ng bug';

  @override
  String get buildADayYouLlRemember => 'Bumuo ng itineraryo';

  @override
  String get buildYourDay => 'Bumuo ng itineraryo';

  @override
  String get buildYourItineraryAndEnjoyAPersonalizedTourExperience =>
      'Bumuo ng itineraryo at mag-enjoy sa paglilibot na ayon sa iyong gusto.';

  @override
  String get buildYourOwnDay => 'Planuhin ang sarili mong araw';

  @override
  String bulletItem(String value) {
    return '• $value';
  }

  @override
  String get bustosBulacan => 'Bustos, Bulacan';

  @override
  String get bustosTourMap => 'Mapa ng paglilibot sa Bustos';

  @override
  String get bustosTownCentre => 'Sentro ng bayan ng Bustos';

  @override
  String get calculatingLocalRoadRoute =>
      'Kinakalkula ang ruta sa mga lokal na daan...';

  @override
  String get callEmergencyServices => 'Tumawag sa serbisyong pang-emerhensiya?';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get cancelBooking => 'Kanselahin ang reserbasyon?';

  @override
  String cancelBookingFeeValue(String value) {
    return 'Kanselahin ang reserbasyon ($value% singil)';
  }

  @override
  String get cancelBookingNoCharge =>
      'Kanselahin ang reserbasyon (walang singil)';

  @override
  String get cancelFree => 'Kanselahin nang walang singil';

  @override
  String get cancelFreeOfCharge => 'Kanselahin nang walang bayad';

  @override
  String get cancellationAndPaymentPolicy =>
      'Patakaran sa pagkansela at pagbabayad';

  @override
  String get cancelled => 'Kinansela';

  @override
  String get cancelledAfterTheGracePeriodPublishedCancellationFeeApplied =>
      'Kinansela matapos ang palugit; inilapat ang nailathalang singil sa pagkansela';

  @override
  String get cancelledWithoutCharge => 'Kinansela nang walang singil';

  @override
  String get cancelThisBooking => 'Kanselahin ang reserbasyong ito?';

  @override
  String get capacity => 'Kapasidad';

  @override
  String caseStatementValue(String value) {
    return 'Salaysay sa kaso: $value';
  }

  @override
  String get cash => 'Cash';

  @override
  String get cashConfirmedByBoth => 'Kinumpirma ng parehong panig ang cash';

  @override
  String get cashConfirmedByBothParties =>
      'Kinumpirma ng parehong panig ang cash';

  @override
  String
  get cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts =>
      'Cash na kinumpirma ng dalawang panig, matapos ang mga ibinalik. Nakaayos ayon sa petsa ng pagtatapos. Hindi kasama ang mga halagang sinusuri.';

  @override
  String get cashNotConfirmed => 'Hindi pa nakumpirma ang cash';

  @override
  String get cashPayment => 'Bayad na cash';

  @override
  String get cashReturn => 'Pagsasauli ng cash';

  @override
  String get cashReturnConfirmed => 'Nakumpirma ang pagsasauli ng cash';

  @override
  String get cashReturnOutstanding => 'Hindi pa naibabalik ang cash';

  @override
  String get cashToReturn => 'Cash na isasauli';

  @override
  String get category => 'Kategorya';

  @override
  String get centerLatitude => 'Latitude ng sentro';

  @override
  String get centerLongitude => 'Longitude ng sentro';

  @override
  String
  get changingServiceCapacityRequiresAdministratorApprovalBeforeYouCanGoOnlineAgain =>
      'Kailangan ng pag-apruba ng administrador ang pagbabago ng kapasidad bago muling mag-online.';

  @override
  String get checkApproval => 'Tingnan ang pag-apruba';

  @override
  String get checkingGpsAndPermission => 'Sinusuri ang GPS at pahintulot.';

  @override
  String get checkLocally => 'Magtanong sa lugar';

  @override
  String get checkoutCouldNotBeCreated => 'Hindi magawa ang checkout.';

  @override
  String checkOutInBustosBulacanValue(String value) {
    return 'Tingnan ang $value sa Bustos, Bulacan! 🏝️';
  }

  @override
  String get checkRoadRestrictions => 'Suriin ang mga paghihigpit sa daan';

  @override
  String get checkYourEmail => 'Tingnan ang email mo';

  @override
  String get chooseABarangayAndEnterTheExactAddressBelow =>
      'Pumili ng barangay at ilagay sa ibaba ang eksaktong address';

  @override
  String get chooseAnExactPickupPointBeforeBooking =>
      'Pumili ng eksaktong sunduan bago magpareserba';

  @override
  String get chooseAPickupPointOnTheMapOrEnableLocationFirst =>
      'Pumili ng sunduan sa mapa o paganahin muna ang lokasyon.';

  @override
  String get chooseBothDocumentsAndExpiryDates =>
      'Piliin ang dalawang dokumento at mga petsa ng pag-expire.';

  @override
  String get chooseFranchiseExpiry => 'Piliin ang pag-expire ng prangkisa';

  @override
  String chooseHowYouWantToUseApp(String brandName) {
    return 'Piliin kung paano mo gagamitin ang $brandName';
  }

  @override
  String get chooseJpegDocumentImages =>
      'Pumili ng mga larawan ng dokumento na JPEG.';

  @override
  String get chooseLicenseExpiry => 'Piliin ang pag-expire ng lisensya';

  @override
  String get chooseLicenseImage => 'Piliin ang larawan ng lisensya';

  @override
  String get choosePickupDate => 'Piliin ang petsa ng sunduan';

  @override
  String get choosePickupTime => 'Piliin ang oras ng sunduan';

  @override
  String get choosePlacesSeeYourFareBookARide =>
      'Pumili ng mga lugar, tingnan ang pamasahe, magpareserba ng sakay.';

  @override
  String get chooseThePlacesYouWantToVisitInOneTrip =>
      'Piliin ang mga lugar na gusto mong puntahan sa isang biyahe.';

  @override
  String get chooseVehicleRegistrationImage =>
      'Piliin ang larawan ng rehistro ng sasakyan';

  @override
  String get chooseWhoShouldReceiveThisAnnouncementThenReviewBeforeSending =>
      'Piliin ang mga tatanggap ng anunsiyo, saka suriin bago ipadala.';

  @override
  String get chooseYourWorkspaceThenSignInToContinue =>
      'Piliin ang iyong workspace, pagkatapos ay mag-sign in upang magpatuloy.';

  @override
  String get church => 'Simbahan';

  @override
  String get cleanVehicle => 'Malinis na sasakyan';

  @override
  String get clearAll => 'Alisin lahat';

  @override
  String get clearSearch => 'Burahin ang paghahanap';

  @override
  String get closeAndNotify => 'Isara at abisuhan';

  @override
  String get closeAttractionDetails => 'Isara ang detalye ng pasyalan';

  @override
  String get closed => 'Sarado';

  @override
  String get closeTemporarily => 'Pansamantalang isara';

  @override
  String get closureReason => 'Dahilan ng pagsasara';

  @override
  String get codeReissueCouldNotBeConfirmed =>
      'Hindi makumpirma ang muling pag-isyu ng code.';

  @override
  String compactCurrency(String value) {
    return '₱${value}k';
  }

  @override
  String get completeAllDocumentAndServiceAreaFields =>
      'Kumpletuhin ang lahat ng dokumento at detalye ng lugar ng serbisyo.';

  @override
  String get completed => 'Natapos';

  @override
  String get completedAndActiveBookings =>
      'Mga natapos at kasalukuyang reserbasyon';

  @override
  String get completedTrips => 'Mga natapos na biyahe';

  @override
  String get completeRefund => 'Tapusin ang refund';

  @override
  String get completeTestModeRefund => 'Tapusin ang refund sa test mode?';

  @override
  String get completeTestModeRefundLabel => 'Tapusin ang refund sa test mode';

  @override
  String get completeTripCashStillUnconfirmed =>
      'Tapusin ang biyahe · hindi pa nakukumpirma ang cash';

  @override
  String get complianceApproved => 'Aprubado ang pagsunod sa mga patakaran';

  @override
  String get complianceReviewRequired =>
      'Kailangan ng pagsusuri ng pagsunod sa mga patakaran';

  @override
  String get complianceReviewSaved =>
      'Na-save ang pagsusuri ng pagsunod sa mga patakaran.';

  @override
  String get confirm => 'Kumpirmahin';

  @override
  String get confirmAmount => 'Kumpirmahin ang halaga';

  @override
  String get confirmAndSend => 'Kumpirmahin at ipadala';

  @override
  String get confirmCashExchanged => 'Kumpirmahing naiabot ang cash?';

  @override
  String get confirmCashPaid => 'Kumpirmahing naibayad ang cash';

  @override
  String get confirmCashReceived => 'Kumpirmahing natanggap ang cash';

  @override
  String get confirmCashReturned => 'Kumpirmahing naibalik ang cash?';

  @override
  String get confirmCashReturnedLabel => 'Kumpirmahing naisauli ang cash';

  @override
  String get confirmCashReturnReceived =>
      'Kumpirmahing natanggap ang isinauling cash';

  @override
  String get confirmChange => 'Kumpirmahin ang pagbabago';

  @override
  String get confirmedCash => 'Nakumpirmang cash';

  @override
  String get confirmedEntriesArePermanentAndCannotBeEditedOrDeleted =>
      'Permanente ang mga nakumpirmang tala at hindi maaaring baguhin o burahin.';

  @override
  String
  get confirmedTransactionsOnlyOpenReviewsAndOutstandingRefundsAreExcluded =>
      'Mga nakumpirmang transaksiyon lamang. Hindi kasama ang mga bukas na pagsusuri at hindi pa naibabalik na bayad.';

  @override
  String get confirmLocation => 'Kumpirmahin ang lokasyon';

  @override
  String get confirmNewPassword => 'Kumpirmahin ang bagong password';

  @override
  String get confirmNoShow => 'Kumpirmahing hindi dumating';

  @override
  String
  confirmOnlyAfterHasPhysicallyChangedHandsTheOtherPartyMustConfirmTooValue(
    String value,
  ) {
    return 'Kumpirmahin lamang kapag aktuwal nang naiabot ang $value. Kailangan ding kumpirmahin ng kabilang panig. Huwag kumpirmahin ang ipinangako pa lamang o bahagyang bayad.';
  }

  @override
  String get confirmPassword => 'Kumpirmahin ang Password';

  @override
  String get confirmRefund => 'Kumpirmahin ang refund';

  @override
  String confirmThatYouStayedAtTheVerifiedPickupPointUntilTheWaitingPeriodValue(
    String value,
    String secondValue,
  ) {
    return 'Kumpirmahing nanatili ka sa beripikadong sunduan hanggang matapos ang oras ng paghihintay at sinubukan mong kontakin ang turista. Ang nailathalang singil na $value% para sa hindi pagsipot ay $secondValue. Itatala ang aksiyong ito at maaari itong kuwestiyunin.';
  }

  @override
  String get confirmThePickupPin => 'Kumpirmahin ang pin sa sunduan';

  @override
  String get confirmYourEmailThenSignInAsADriverToFinishUploadingYour =>
      'Kumpirmahin ang iyong email, saka mag-sign in bilang drayber upang tapusin ang pag-upload ng iyong aplikasyon.';

  @override
  String get connectionUnavailableCheckYourInternetConnectionAndTryAgain =>
      'Walang koneksiyon. Suriin ang internet at subukan muli.';

  @override
  String get connectToTheInternetAndRetry =>
      'Kumonekta sa internet at subukang muli.';

  @override
  String get contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown =>
      'Hindi makuha ang mga bagong kontak. Pambansang fallback lamang ang ipinapakita.';

  @override
  String get couldNotGetACurrentGpsPositionCheckYourSignalAndTryAgain =>
      'Hindi makuha ang kasalukuyang GPS. Suriin ang signal at subukan muli.';

  @override
  String
  get couldNotGoOfflineLocationSharingRemainsActiveUntilTheServerConfirmsIt =>
      'Hindi makapag-offline. Aktibo pa ang pagbabahagi ng lokasyon hanggang makumpirma ng server.';

  @override
  String get couldNotGoOnlineYourAvailabilityWasNotChanged =>
      'Hindi makapag-online. Hindi nagbago ang iyong availability.';

  @override
  String get couldNotLaunchPhoneDialer => 'Hindi mabuksan ang pantawag';

  @override
  String couldNotLaunchValue(String value) {
    return 'Hindi mabuksan ang $value';
  }

  @override
  String get couldNotOpenCheckoutResumePaymentFromThisBooking =>
      'Hindi mabuksan ang pahina ng bayad. Ipagpatuloy ang pagbabayad mula sa reserbasyon na ito.';

  @override
  String get couldNotOpenMessages => 'Hindi mabuksan ang mga mensahe.';

  @override
  String get couldNotOpenNavigation => 'Hindi mabuksan ang nabigasyon.';

  @override
  String get couldNotOpenPhoneDialer => 'Hindi mabuksan ang dialer.';

  @override
  String get couldNotOpenThePhoneDialerCall911Manually =>
      'Hindi mabuksan ang dialer. Mano-manong tumawag sa 911.';

  @override
  String get couldNotOpenThePhoneDialerCallTheDisplayedNumberManually =>
      'Hindi mabuksan ang dialer ng telepono. Manu-manong tawagan ang nakasaad na numero.';

  @override
  String get couldNotOpenThisDocument => 'Hindi mabuksan ang dokumentong ito.';

  @override
  String get couldNotSaveNoBookingOrPaymentStateWasChanged =>
      'Hindi ma-save. Walang nabago sa reserbasyon o bayad.';

  @override
  String get couldNotSaveThisChangePleaseRetryThePreviousTripStateHasBeen =>
      'Hindi ma-save ang pagbabago. Subukan muli; nananatili ang dating katayuan ng biyahe.';

  @override
  String get couldNotSynchronizeWithTheServerCheckYourConnectionAndRetry =>
      'Hindi makasabay sa server. Suriin ang koneksiyon at subukang muli.';

  @override
  String get createANewPassword => 'Gumawa ng bagong password';

  @override
  String get createTouristAccount => 'Gumawa ng Account ng Turista';

  @override
  String
  get criticalConditionsAlsoAppearInOperationalAlertsInvestigateBeforeClearingAnAlert =>
      'Makikita rin ang mga kritikal na kondisyon sa mga alerto sa operasyon. Siyasatin muna bago alisin ang alerto.';

  @override
  String get curatedExperience => 'Piniling karanasan';

  @override
  String get currentGpsLocation => 'Kasalukuyang lokasyon sa GPS';

  @override
  String get currentGpsPickup => 'Kasalukuyang sunduan mula sa GPS';

  @override
  String get currentLocation => 'Kasalukuyang lokasyon';

  @override
  String get customTour => 'Sariling paglilibot';

  @override
  String get customTour112SelectedStops =>
      'Pasadyang tour (1–12 napiling hintuan)';

  @override
  String
  customTourNewBookingsUseTheseRatesExistingBookingsKeepTheirAgreedFareValue(
    String value,
    String secondValue,
  ) {
    return 'Pasadyang tour: ₱$value\n$secondValue\n\nGagamitin ng mga bagong reserbasyon ang mga presyong ito. Mananatili ang napagkasunduang pamasahe ng mga kasalukuyang reserbasyon.';
  }

  @override
  String get dataExportRequests => 'Mga kahilingan ng export ng data';

  @override
  String daysAgoValue(String value) {
    return '$value araw ang nakalipas';
  }

  @override
  String get dec => 'Dis';

  @override
  String get decisionAndReasoning => 'Pasiya at paliwanag';

  @override
  String get decline => 'Tanggihan';

  @override
  String get decliningMatchedOffersRequiresTheConfiguredServer =>
      'Kailangan ang naka-configure na server upang tanggihan ang itinugmang alok.';

  @override
  String get delete => 'Burahin';

  @override
  String get deleteAccount => 'Burahin ang account?';

  @override
  String deletedValue(String value) {
    return 'Nabura ang $value';
  }

  @override
  String get deleteMyAccount => 'Burahin ang aking account';

  @override
  String get deletingAccount => 'Binubura ang account…';

  @override
  String get deletionPending => 'Naghihintay ang pagbura';

  @override
  String
  get describeTheDisagreementCollectionAndRefundConfirmationsWillPauseUntilAnAdminReviews =>
      'Ilarawan ang hindi pagkakasundo. Ihihinto muna ang mga kumpirmasyon sa paniningil at refund hanggang masuri ito ng admin.';

  @override
  String get description => 'Paglalarawan';

  @override
  String get destination => 'Patutunguhan';

  @override
  String get destinations => 'Mga destinasyon';

  @override
  String get destinationsYouLove => 'Mga destinasyon na gusto mo';

  @override
  String get directions => 'Mga direksiyon';

  @override
  String get directionsRequireBetween2And25Coordinates =>
      'Kailangan ng 2 hanggang 25 coordinate para sa direksiyon.';

  @override
  String get discover => 'Tuklasin';

  @override
  String get discoverBustos => 'Tuklasin ang Bustos';

  @override
  String get disputePaymentReportAProblem =>
      'Kuwestiyunin ang pagbabayad / mag-ulat ng problema';

  @override
  String distanceKilometers(String value) {
    return '$value km';
  }

  @override
  String distanceMeters(String value) {
    return '$value m';
  }

  @override
  String documentsAreWaitingForVerificationValue(String value) {
    return '$value dokumento ang naghihintay ng beripikasyon';
  }

  @override
  String get documentsDatesServiceAreaAndReliabilityMeetTheMatchingRules =>
      'Pasado sa mga tuntunin ang mga dokumento, petsa, lugar ng serbisyo at pagiging maaasahan.';

  @override
  String get documentsPassword => 'Mga Dokumento at Password';

  @override
  String get done => 'Tapos na';

  @override
  String get donTHaveAnAccount => 'Wala pang account?';

  @override
  String get downloadExport => 'I-download ang export';

  @override
  String get dragTheMapToPinYourExactLocation =>
      'I-drag ang mapa upang i-pin ang eksaktong lokasyon';

  @override
  String get drive => 'Magmaneho';

  @override
  String get driver => 'Drayber';

  @override
  String get driverAcceptedTheFixedFareAndPickup =>
      'Tinanggap ng drayber ang takdang pamasahe at sunduan.';

  @override
  String get driverAccount => 'Account ng drayber';

  @override
  String get driverApplication => 'Aplikasyon ng drayber';

  @override
  String get driverApprovedAndMatchingEnabled =>
      'Aprubado na ang drayber at maaari nang itugma sa mga biyahe.';

  @override
  String get driverArrival => 'Pagdating ng drayber';

  @override
  String get driverArrivedAtTheVerifiedPickupAreaTheWaitingPeriodStarted =>
      'Dumating ang drayber sa beripikadong sunduan. Nagsimula ang oras ng paghihintay.';

  @override
  String get driverBookings => 'Mga reserbasyon ng drayber';

  @override
  String get driverCancellationRateExceedsThe30MatchingLimit =>
      'Lampas sa 30% na limitasyon ang pagkansela ng drayber.';

  @override
  String get driverCancellations => 'Mga pagkansela ng drayber';

  @override
  String get driverCompliance => 'Pagsunod ng drayber sa mga patakaran';

  @override
  String get driverComplianceRecordsWillAppearHere =>
      'Dito makikita ang mga tala ng pagsunod ng drayber sa mga patakaran.';

  @override
  String get driverConcern => 'Alalahanin tungkol sa drayber';

  @override
  String get driverDocumentsMustBeJpegImages5MbMaximumEach =>
      'Dapat JPEG na larawan ang mga dokumento ng drayber, hanggang 5 MB bawat isa.';

  @override
  String get driverHasArrived => 'Dumating na ang drayber';

  @override
  String get driverIsMoving => 'Papalapit ang drayber';

  @override
  String get driverIsStopped => 'Huminto ang drayber';

  @override
  String get driverLicense => 'Lisensya ng drayber';

  @override
  String get driverLicenseDocumentIsMissing =>
      'Walang dokumento ng lisensya ng drayber.';

  @override
  String get driverLicenseExpiry => 'Pag-expire ng lisensiya';

  @override
  String get driverMatchingBegins30MinutesBeforePickup =>
      'Magsisimula ang paghahanap ng drayber 30 minuto bago ang sunduan.';

  @override
  String get driverNotFound => 'Hindi makita ang drayber';

  @override
  String get driverPerformance => 'Pagganap ng drayber';

  @override
  String get driverRegistration => 'Pagpaparehistro ng Drayber';

  @override
  String get driverReplacementRequested => 'Humiling ng kapalit na drayber';

  @override
  String get driverReplacementRequiresTheConfiguredServer =>
      'Kailangan ang naka-configure na server upang magpalit ng drayber.';

  @override
  String get driverReportedArrivalAwaitingTourist =>
      'Dumating na ang drayber · hinihintay ang turista';

  @override
  String get driverReviewSubmitted => 'Naisumite ang review ng drayber.';

  @override
  String get drivers => 'Mga drayber';

  @override
  String driversActiveValue(String value) {
    return 'Aktibong drayber: $value';
  }

  @override
  String get driverSearchRetriedForAnother10Minutes =>
      'Muling maghahanap ng drayber sa loob ng 10 minuto.';

  @override
  String driversHaveToAcceptThisSearchRequestYouCanLeaveThisScreenAndValue(
    String value,
  ) {
    return 'May $value ang mga drayber upang tanggapin ang kahilingang ito. Maaari kang umalis sa screen at bumalik sa Mga biyahe. Walang singil habang naghihintay.';
  }

  @override
  String get driverSuspendedFor30Days =>
      'Sinuspinde ang drayber sa loob ng 30 araw.';

  @override
  String get driverTools => 'Mga kasangkapan ng drayber';

  @override
  String get driverTrackingPreview => 'Preview ng pagsubaybay sa drayber';

  @override
  String driverValue(String value) {
    return 'Drayber: $value';
  }

  @override
  String get driverVerifications => 'Beripikasyon ng mga drayber';

  @override
  String get eachDriverDocumentMustBe5MbOrSmaller =>
      'Dapat 5 MB o mas maliit ang bawat dokumento ng drayber.';

  @override
  String get earlier => 'Mas maaga';

  @override
  String get earnings => 'Kita';

  @override
  String get earningsInsights => 'Buod ng kita';

  @override
  String get edit => 'I-edit';

  @override
  String get editProfile => 'I-edit ang Profile';

  @override
  String get editTouristSpot => 'I-edit ang Pasyalan';

  @override
  String get eG123RizalStNearTheBakery =>
      'Hal. 123 Rizal St., malapit sa panaderya';

  @override
  String get eGMinasaFestivalGrounds => 'hal. Minasa Festival Grounds';

  @override
  String get eGSystemMaintenance => 'hal. Pagpapanatili ng Sistema';

  @override
  String get email => 'Email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressIsRequired => 'Kailangan ang email address';

  @override
  String emailAddressMustNotExceedCharactersValue(String value) {
    return 'Hindi dapat lumampas sa $value karakter ang email address';
  }

  @override
  String get emailIsRequired => 'Kailangan ang email';

  @override
  String get emailReadOnly => 'Email (Hindi nae-edit)';

  @override
  String get emergency => 'Emerhensiya';

  @override
  String get emergencyContact => 'Kontak sa emergency';

  @override
  String get emergencyContacts => 'Mga Kontak sa Emerhensiya';

  @override
  String get emergencyContactsSettings => 'Mga setting ng kontak sa emergency';

  @override
  String get emergencyHelp => 'Tulong sa emerhensiya';

  @override
  String get emergencySafety => 'Emergency at Kaligtasan';

  @override
  String get endSafelyReviewPayment => 'Tapusin nang ligtas · suriin ang bayad';

  @override
  String get endTheTourSafelyFirstToOpenASettlementReview =>
      'Tapusin muna nang ligtas ang tour bago magbukas ng pagsusuri ng bayad.';

  @override
  String get endTourEarly => 'Tapusin nang maaga ang paglilibot?';

  @override
  String get endTourEarlyReportAProblem =>
      'Maagang tapusin ang paglilibot / mag-ulat ng problema';

  @override
  String get english => 'English';

  @override
  String get englishName => 'Pangalan sa Ingles';

  @override
  String get enterAClearClosureReason =>
      'Maglagay ng malinaw na dahilan ng pagsasara.';

  @override
  String get enterAClearReasonForTheAuditHistory =>
      'Maglagay ng malinaw na dahilan para sa tala ng pagsusuri';

  @override
  String get enterAClearReasonForThisChange =>
      'Maglagay ng malinaw na dahilan ng pagbabagong ito.';

  @override
  String get enterAddress => 'Ilagay ang address...';

  @override
  String get enterAnAdminEmail => 'Maglagay ng email ng admin';

  @override
  String get enterAPhMobileNumberOrInternationalNumberWithCountryCode =>
      'Maglagay ng PH mobile number o internasyonal na numero na may +country code';

  @override
  String get enterAPriceBetween001And100000 =>
      'Maglagay ng presyong mula ₱0.01 hanggang ₱100,000.';

  @override
  String get enterAReasonOfAtLeastFiveCharacters =>
      'Maglagay ng dahilan na may hindi bababa sa limang karakter.';

  @override
  String get enterAValidAmountWithAtMostTwoDecimals =>
      'Maglagay ng wastong halaga na hanggang dalawang decimal.';

  @override
  String get enterAValidEmail => 'Maglagay ng wastong email';

  @override
  String get enterAValidPhoneNumber => 'Maglagay ng wastong numero ng telepono';

  @override
  String get enterAValidPrice => 'Maglagay ng wastong presyo';

  @override
  String get enterDescription => 'Ilagay ang paglalarawan...';

  @override
  String get enterDriverApp => 'Pumasok sa drayber app';

  @override
  String get enterHistory => 'Ilagay ang kasaysayan...';

  @override
  String get enterPesosWithAtMostTwoDecimalPlaces =>
      'Maglagay ng halaga sa piso na hanggang dalawang decimal.';

  @override
  String get enterThePickupAddressBelow =>
      'Ilagay sa ibaba ang address ng sunduan.';

  @override
  String
  get enterTheReasonForApprovingOrRestoringServiceAtLeastFiveCharacters =>
      'Ilagay ang dahilan ng pag-apruba o pagpapanumbalik ng serbisyo (hindi bababa sa limang karakter).';

  @override
  String get enterTouristApp => 'Pumasok sa turista app';

  @override
  String get enterValidFixedFaresForEveryRoute =>
      'Maglagay ng wastong takdang pamasahe para sa bawat ruta.';

  @override
  String get enterYourAnnouncementDetailsHere =>
      'Ilagay ang mga detalye ng anunsiyo rito...';

  @override
  String get enterYourEmail => 'Ilagay ang iyong email';

  @override
  String get enterYourEmailAndWeWillSendYouALinkToResetYour =>
      'Ilagay ang email mo at magpapadala kami ng link para palitan ang password.';

  @override
  String get enterYourFullName => 'Ilagay ang iyong buong pangalan';

  @override
  String get enterYourPassword => 'Ilagay ang iyong password';

  @override
  String get entranceFee => 'Bayad sa Pagpasok';

  @override
  String get entranceFeesMayApply => '+ maaaring may entrance fee';

  @override
  String get eta => 'Tinatayang Oras ng Pagdating';

  @override
  String get exampleEmailCom => 'example@email.com';

  @override
  String get exampleSeniorPassengerNeedsExtraBoardingTime =>
      'Halimbawa: kailangan ng dagdag na oras sa pagsakay ng nakatatandang pasahero';

  @override
  String get exampleTwoBackpacksAndOneFoldingStroller =>
      'Halimbawa: dalawang backpack at isang natitiklop na stroller';

  @override
  String get exampleUpdatedOperatingCostApprovedByAdmin =>
      'Halimbawa: Bagong gastusin sa operasyon na aprubado ng admin';

  @override
  String get expectedReopening => 'Inaasahang muling pagbubukas';

  @override
  String expectedReopeningValue(String value) {
    return 'Inaasahang muling pagbubukas: $value';
  }

  @override
  String expiryIsNotVerifiedValue(String value) {
    return 'Hindi beripikado ang petsa ng pag-expire ng $value.';
  }

  @override
  String get expiryVerification => 'Beripikasyon ng pag-expire';

  @override
  String get explainAnythingTheDriverMustCorrect =>
      'Ipaliwanag ang kailangang itama ng drayber';

  @override
  String get explainTheDecisionAtLeast10Characters =>
      'Ipaliwanag ang desisyon (hindi bababa sa 10 karakter).';

  @override
  String get explainTheDecisionClearly =>
      'Ipaliwanag nang malinaw ang desisyon';

  @override
  String get explainThePolicyInAtLeast20Characters =>
      'Ipaliwanag ang patakaran gamit ang hindi bababa sa 20 karakter.';

  @override
  String get explore => 'Tuklasin';

  @override
  String get exploreBustos => 'Mga Kalapit na Lugar';

  @override
  String get exploreSpotsBuildItinerariesAndBookTricyclesEasily =>
      'Madaling tumuklas ng mga pasyalan, bumuo ng itineraryo at magpareserba ng traysikel.';

  @override
  String get exploreTheHeritageNatureAndBeautyOfBustosBulacanWithEase =>
      'Madaling tuklasin ang pamana, kalikasan at ganda ng Bustos, Bulacan.';

  @override
  String get exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited =>
      'Sa humiling na account lamang ibinibigay ang export. Itinatala ang pagtupad sa kahilingan.';

  @override
  String get f123456 => 'F-123456';

  @override
  String get failedPayments => 'Mga nabigong pagbabayad';

  @override
  String get feb => 'Peb';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackMarkedResolved => 'Minarkahang nalutas ang feedback';

  @override
  String get feedbackSubmittedThankYou => 'Naipadala ang feedback! Salamat 🙏';

  @override
  String get filipino => 'Filipino';

  @override
  String get filipinoName => 'Pangalan sa Filipino';

  @override
  String get finalCharge => 'Huling singil (₱)';

  @override
  String get finalChargeLabel => 'Huling singil';

  @override
  String finalChargeValue(String value, String secondValue) {
    return 'Huling singil: ₱$value · $secondValue';
  }

  @override
  String get financeAdministratorAccessIsRequired =>
      'Kailangan ang access ng administrador ng pananalapi.';

  @override
  String get financialRecord => 'Tala ng transaksiyon';

  @override
  String get findADriver => 'Maghanap ng drayber';

  @override
  String get findAnotherDriver => 'Maghanap ng ibang drayber';

  @override
  String get findAnotherDriverLabel => 'Maghanap ng ibang drayber?';

  @override
  String get findingYourLocation => 'Hinahanap ang iyong lokasyon…';

  @override
  String get findMyDriver => 'Hanapin ang aking drayber';

  @override
  String get finishOrCancelTheActiveTripBeforeGoingOffline =>
      'Tapusin o kanselahin ang kasalukuyang biyahe bago mag-offline.';

  @override
  String get finishYourCurrentTripBeforeAcceptingAnother =>
      'Tapusin muna ang kasalukuyang biyahe bago tumanggap ng iba.';

  @override
  String get fixedFare => 'Nakapirming pamasahe';

  @override
  String fixedFareAcceptedCancellationPaymentPolicyV1AcceptedValue(
    String value,
  ) {
    return 'Tinanggap ang nakapirming pamasahe na ₱$value at patakaran sa pagkansela at pagbabayad na bersiyon 1.';
  }

  @override
  String get fixedFareForThisRoute => 'Nakapirming pamasahe para sa rutang ito';

  @override
  String get fixedFares => 'Mga takdang pamasahe';

  @override
  String get fixedFaresSavedExistingBookingPricesAreUnchanged =>
      'Na-save ang mga takdang pamasahe. Hindi nagbago ang presyo ng mga kasalukuyang reserbasyon.';

  @override
  String fixedFareValue(String value) {
    return 'Nakapirming pamasahe: ₱$value';
  }

  @override
  String get fixedItinerary => 'Nakapirming itineraryo';

  @override
  String get flag => 'Markahan';

  @override
  String flutterFailureValue(String value) {
    return 'Pagpalya ng Flutter: $value';
  }

  @override
  String get forgotPassword => 'Nakalimutang password';

  @override
  String get forgotPasswordLabel => 'Nakalimutan ang Password?';

  @override
  String forImmediateDangerCall911AppDoesNotReplaceEmergencyServices(
    String brandName,
  ) {
    return 'Kung may agarang panganib, tumawag sa 911. Hindi kapalit ng serbisyong pang-emerhensiya ang $brandName.';
  }

  @override
  String get formattedValue => ' → ';

  @override
  String get fr12345 => 'FR-12345';

  @override
  String get franchise => 'Prangkisa';

  @override
  String get franchiseExpiresOn => 'franchise_expires_on';

  @override
  String get franchiseExpiryDate => 'Petsa ng pag-expire ng prangkisa';

  @override
  String get franchiseNumber => 'Numero ng Prangkisa';

  @override
  String get franchiseNumberIsRequired => 'Kailangan ang numero ng prangkisa';

  @override
  String get franchiseOrCr => 'Prangkisa / OR-CR';

  @override
  String get franchiseOrCrDocumentIsMissing =>
      'Walang dokumento ng prangkisa / OR-CR.';

  @override
  String get franchiseOrCrExpiry => 'Pag-expire ng prangkisa / OR-CR';

  @override
  String get franchiseOrCrLabel => 'OR/CR ng prangkisa';

  @override
  String get franchiseOrCrNumberIsRequired =>
      'Kailangan ang numero ng prangkisa/OR-CR';

  @override
  String franchiseOrCrNumberMustNotExceedCharactersValue(String value) {
    return 'Hindi dapat lumampas sa $value karakter ang numero ng prangkisa/OR-CR';
  }

  @override
  String franchiseValue(String value) {
    return 'Prangkisa: $value';
  }

  @override
  String get freeCancellation => 'Libreng pagkansela';

  @override
  String
  freeCancellationMinutesLateTouristCancellationVerifiedPickupWaitMinutesTouristNoShowValue(
    String value,
    String secondValue,
    String thirdValue,
    String fourthValue,
  ) {
    return 'Libreng pagkansela: $value minuto\nHuling pagkansela ng turista: $secondValue%\nBeripikadong paghihintay sa sunduan: $thirdValue minuto\nBayad sa hindi pagsipot: $fourthValue%\n\nPananatilihin ng mga kasalukuyang reserbasyon ang orihinal na patakaran.';
  }

  @override
  String get fri => 'Biy';

  @override
  String get fromPickup => 'mula sa sunduan';

  @override
  String fromValue(String value, String secondValue) {
    return '$value mula kay $secondValue';
  }

  @override
  String get fromYou => 'mula sa iyo';

  @override
  String get fulfilled => 'natupad';

  @override
  String get fullName => 'Buong pangalan';

  @override
  String get fullNameIsRequired => 'Kailangan ang buong pangalan';

  @override
  String get getAroundQuicklyAndSafelyByBookingLocalTricycleDriversInSeconds =>
      'Mabilis at ligtas na bumiyahe sa pamamagitan ng pagpapareserba sa mga lokal na drayber ng traysikel.';

  @override
  String get getStarted => 'Magsimula';

  @override
  String get goBack => 'Bumalik';

  @override
  String get goodAfternoon => 'Magandang hapon';

  @override
  String get goodEvening => 'Magandang gabi';

  @override
  String get goodMorning => 'Magandang umaga';

  @override
  String goodMorningValue(String value) {
    return 'Magandang umaga, $value';
  }

  @override
  String get goOnlineToActivateTheDriverMap =>
      'Mag-online upang i-activate ang mapa ng drayber.';

  @override
  String get goOnlineToStartReceivingBookingRequests =>
      'Mag-online upang makatanggap ng mga kahilingan ng reserbasyon.';

  @override
  String get goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept =>
      'Mag-online gamit ang aprubadong account at tapusin ang kasalukuyang biyahe bago tumanggap ng bagong kahilingan.';

  @override
  String get goOnlineWithAnApprovedDriverAccountFirst =>
      'Mag-online muna gamit ang aprubadong account ng drayber.';

  @override
  String get greatRideVeryKnowledgeableAboutBustos =>
      'Magandang biyahe, mahusay ang kaalaman tungkol sa Bustos!';

  @override
  String get headingTo => 'Papunta sa';

  @override
  String get headingToPickup => 'Papunta sa Sunduan';

  @override
  String get help => 'Tulong';

  @override
  String get helpSupport => 'Tulong at suporta';

  @override
  String get heritage => 'Pamana';

  @override
  String get hidden => 'Nakatago';

  @override
  String hideValue(String value) {
    return 'Itago ang $value';
  }

  @override
  String get history => 'Kasaysayan';

  @override
  String hoursAgoValue(String value) {
    return '$value oras ang nakalipas';
  }

  @override
  String howWasYourRideWithValue(String value) {
    return 'Kumusta ang iyong biyahe kasama si $value?';
  }

  @override
  String get iAgreeToTheFixedFareAndCancellationPaymentPolicy =>
      'Sumasang-ayon ako sa nakapirming pamasahe at sa patakaran sa pagkansela at pagbabayad.';

  @override
  String get iAgreeToTheTermsAndConditions =>
      'Sumasang-ayon ako sa mga Tuntunin at Kondisyon';

  @override
  String get iAmA => 'Ako ay isang...';

  @override
  String get ifPlansChange => 'Kung magbago ang plano';

  @override
  String get iHaveReadAndAcceptThisNotice =>
      'Nabasa ko at tinatanggap ang abisong ito.';

  @override
  String get iHaveReadTheNoticeAndAgreeToTheDataUseNeededTo =>
      'Nabasa ko ang abiso at pumapayag ako sa paggamit ng datos na kailangan para sa aking account at mga biyahe.';

  @override
  String get imageContentMimeTypeAndFileExtensionMustMatch =>
      'Dapat magkatugma ang laman ng larawan, MIME type at extension ng file.';

  @override
  String get includedStops => 'Mga kasamang hinto';

  @override
  String
  get includeWhatHappenedWhereTheTripStoppedAndAnyCashAlreadyExchangedStatements =>
      'Isama ang nangyari, kung saan huminto ang biyahe at ang cash na naiabot na. Pananatilihin ang mga salaysay kasama ng reserbasyon.';

  @override
  String get incomingBooking => 'Papasok na reserbasyon';

  @override
  String get incomingPickup => 'Papasok na sunduan';

  @override
  String informationProvidedByAppAdministrators(String brandName) {
    return 'Impormasyong ibinigay ng mga admin ng $brandName';
  }

  @override
  String get interactiveMapsAreAvailableInTheMobileApp =>
      'Sa mobile app magagamit ang interactive na mapa.';

  @override
  String get invalidAdminCredentials =>
      'Hindi wastong mga kredensiyal ng admin';

  @override
  String get invalidAppBuild => 'Hindi wastong build ng app';

  @override
  String get invalidAttractionImageOwner =>
      'Hindi wasto ang may-ari ng larawan ng pasyalan.';

  @override
  String get invalidAttractionImageVersion =>
      'Hindi wasto ang bersiyon ng larawan ng pasyalan.';

  @override
  String get invalidLatitude => 'Hindi wastong latitude';

  @override
  String get invalidLongitude => 'Hindi wastong longitude';

  @override
  String isExpiredValue(String value) {
    return 'Expired na ang $value.';
  }

  @override
  String isNowHiddenValue(String value) {
    return 'Nakatago na ngayon ang $value';
  }

  @override
  String isNowVisibleValue(String value) {
    return 'Nakikita na ngayon ang $value';
  }

  @override
  String isRequiredValue(String value) {
    return 'Kailangan ang $value';
  }

  @override
  String isTemporarilyClosedAndCannotBeAddedRightNow(String spot) {
    return 'Pansamantalang sarado ang $spot at hindi maidagdag ngayon.';
  }

  @override
  String get itinerary => 'Itineraryo';

  @override
  String get iVerifiedThisNumberWithTheAgency =>
      'Kinumpirma ko ang numerong ito sa ahensiya.';

  @override
  String get jan => 'Ene';

  @override
  String get jobs => 'Mga biyahe';

  @override
  String get johnDoe => 'John doe';

  @override
  String get johnExampleCom => 'john@example.com';

  @override
  String get juanDelaCruz => 'Juan Dela Cruz';

  @override
  String get juanExampleCom => 'juan@example.com';

  @override
  String get jul => 'Hul';

  @override
  String get jun => 'Hun';

  @override
  String get justNow => 'Ngayon lang';

  @override
  String get keepAccount => 'Panatilihin ang account';

  @override
  String get keepCurrentCode => 'Panatilihin ang kasalukuyang code';

  @override
  String get keepEditing => 'Ipagpatuloy ang pag-edit';

  @override
  String get keepOpen => 'Panatilihing bukas';

  @override
  String get keepOriginalRoute => 'Panatilihin ang orihinal na ruta';

  @override
  String get keepUnderReview => 'Panatilihin sa pagsusuri';

  @override
  String get keepWaiting => 'Maghintay pa';

  @override
  String kmAwayValue(String value, String secondValue) {
    return '$value • $secondValue km ang layo';
  }

  @override
  String kmAwayValueLabel(String value) {
    return '$value km ang layo';
  }

  @override
  String kmValue(String value) {
    return ' $value km';
  }

  @override
  String get language => 'Wika';

  @override
  String get lastLocationIsMoreThanAMinuteOld =>
      'Huling lokasyon ay mahigit isang minuto na';

  @override
  String get lateCancellation => 'Huling pagkansela';

  @override
  String get lateCancellationFee => 'Bayad sa huling pagkansela';

  @override
  String get latitude => 'Latitude';

  @override
  String get leaveACommentOptional => 'Mag-iwan ng komento (opsiyonal)';

  @override
  String get leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder =>
      'Iwanang walang laman ang numero upang manatiling malinaw na placeholder.';

  @override
  String get licenseExpiresOn => 'license_expires_on';

  @override
  String get licenseExpiryDate => 'Petsa ng pag-expire ng lisensiya';

  @override
  String get licenseImageSelected => 'Napili na ang larawan ng lisensya';

  @override
  String licenseValue(String value) {
    return 'Lisensya: $value';
  }

  @override
  String get listView => 'Listahan';

  @override
  String get liveDriverTracking => 'Live na Pagsubaybay sa Drayber';

  @override
  String get liveLocationIsActiveForTripMatching =>
      'Aktibo ang live na lokasyon para sa pagtutugma ng biyahe';

  @override
  String get liveLocationIsReconnectingKeepTheAppOpen =>
      'Muling kumokonekta ang live na lokasyon. Panatilihing bukas ang app.';

  @override
  String get liveMapboxTrackingIsAvailableInTheMobileApp =>
      'Sa mobile app magagamit ang live na pagsubaybay sa Mapbox.';

  @override
  String get liveOverview => 'Live na pangkalahatang-ideya';

  @override
  String get loading => 'Naglo-load';

  @override
  String get loadingMore => 'Naglo-load pa…';

  @override
  String get loadMore => 'Mag-load pa';

  @override
  String get loadMoreBookings => 'Mag-load pa ng mga reserbasyon';

  @override
  String get loadMorePeople => 'Mag-load pa ng mga tao';

  @override
  String get localContactsAndSos => 'Mga lokal na kontak at SOS';

  @override
  String get localEmergencyNumbers => 'Mga Lokal na Numero ng Emergency';

  @override
  String get localHistory => 'Kasaysayan ng lugar';

  @override
  String get localRoadsArePreferredFollowRoadSignsAndYourApprovedTodaOrLgu =>
      'Mas pinipili ang mga lokal na daan. Sundin ang mga karatula at rutang aprubado ng TODA o LGU.';

  @override
  String get locationIsUnavailableRightNowCheckYourSettingsAndTryAgain =>
      'Hindi makuha ang lokasyon ngayon. Suriin ang mga setting at subukan muli.';

  @override
  String get locationPermissionDeniedEnableItInSettings =>
      'Tinanggihan ang pahintulot sa lokasyon. Payagan ito sa Mga setting.';

  @override
  String get locationPermissionIsNeededToReceiveRides =>
      'Kailangan ang pahintulot sa lokasyon upang makatanggap ng biyahe.';

  @override
  String get locationPermissionIsNeededToUseYourCurrentPosition =>
      'Kailangan ang pahintulot sa lokasyon upang magamit ang kasalukuyang posisyon.';

  @override
  String get locationServicesAreDisabledPleaseEnableGps =>
      'Naka-off ang serbisyo ng lokasyon. I-on ang GPS.';

  @override
  String get locationSharingIsAlreadyStopped =>
      'Nakahinto na ang pagbabahagi ng lokasyon.';

  @override
  String get locationSharingIsNoLongerAvailableOnThisScreen =>
      'Hindi na available ang pagbabahagi ng lokasyon sa pahinang ito.';

  @override
  String get locationSharingIsOff => 'Naka-off ang pagbabahagi ng lokasyon';

  @override
  String get locationSharingWasCancelled =>
      'Kinansela ang pagbabahagi ng lokasyon.';

  @override
  String get locationUnavailable => 'Hindi makuha ang lokasyon';

  @override
  String get login => 'Mag-login';

  @override
  String get logOut => 'Mag-log out';

  @override
  String get logOutLabel => 'Mag-log Out?';

  @override
  String get longitude => 'Longitude';

  @override
  String get lookingForADriver => 'Naghahanap ng drayber';

  @override
  String get lostPickupCodeReissue => 'Nawala ang sunduan code? Palitan';

  @override
  String get luggageOrBulkyItems => 'Bagahe o malalaking gamit';

  @override
  String get makeItYourOwn => 'Iayon sa iyong gusto';

  @override
  String get manageTourists => 'Pamahalaan ang mga turista';

  @override
  String get mapView => 'Tingnan sa mapa';

  @override
  String get mar => 'Mar';

  @override
  String get mariaExampleCom => 'maria@example.com';

  @override
  String get markAllAsRead => 'Markahang nabasa ang lahat';

  @override
  String get markAllRead => 'Markahang nabasa lahat';

  @override
  String get market => 'Pamilihan';

  @override
  String get matchingBlockers => 'Mga hadlang sa pagtutugma';

  @override
  String get matchingIsTemporarilyBlocked =>
      'Pansamantalang hinaharang ang pagtutugma.';

  @override
  String get matchWithTouristsWhoDescribeMobilityOrBoardingNeeds =>
      'Tumanggap ng turistang nangangailangan ng tulong sa pagkilos o pagsakay.';

  @override
  String get maximumCapacityIsCheckedBeforeOfferingTheBooking =>
      'Sinusuri ang kapasidad bago ialok ang reserbasyon.';

  @override
  String get may => 'May';

  @override
  String get member => 'Miyembro';

  @override
  String get message => 'Mensahe';

  @override
  String get min8Characters => 'Hindi bababa sa 8 karakter';

  @override
  String get min8Chars => 'Hindi bababa sa 8 karakter';

  @override
  String minsAgoValue(String value) {
    return '$value minuto ang nakalipas';
  }

  @override
  String get minutes => 'minuto';

  @override
  String minValue(String value, String secondValue) {
    return '$value · $secondValue minuto';
  }

  @override
  String minValueLabel(String value, String secondValue) {
    return '$value min · $secondValue';
  }

  @override
  String missingValue(String value) {
    return 'Wala ang $value';
  }

  @override
  String modeValue(String value) {
    return 'Mode: $value';
  }

  @override
  String modeValueLabel(String value, String secondValue, String thirdValue) {
    return '$value · mode: $secondValue\n$thirdValue';
  }

  @override
  String get mon => 'Lun';

  @override
  String get moveTheMapPinOrUseYourCurrentLocationBeforeSaving =>
      'Ilipat ang pin o gamitin ang kasalukuyang lokasyon bago i-save.';

  @override
  String mustBeAtLeastCharactersValue(String value, String secondValue) {
    return 'Dapat may hindi bababa sa $secondValue karakter ang $value';
  }

  @override
  String mustNotExceedCharactersValue(String value, String secondValue) {
    return 'Hindi dapat lumampas sa $secondValue karakter ang $value';
  }

  @override
  String get myBookings => 'Aking mga reserbasyon';

  @override
  String get myData => 'Aking data';

  @override
  String get myLocation => 'Aking lokasyon';

  @override
  String get name => 'Pangalan';

  @override
  String get nameMustBeAtLeast2Characters =>
      'Dapat may hindi bababa sa 2 karakter ang pangalan';

  @override
  String nameMustNotExceedCharactersValue(String value) {
    return 'Hindi dapat lumampas sa $value karakter ang pangalan';
  }

  @override
  String get namePlateFranchiseOrServiceArea =>
      'Pangalan, plaka, prangkisa o lugar ng serbisyo';

  @override
  String get nationalEmergencyHotline => 'Pambansang Hotline ng Emergency';

  @override
  String get nature => 'Kalikasan';

  @override
  String get navigate => 'Mag-navigate';

  @override
  String get needsReview => 'Kailangang suriin';

  @override
  String get newPassword => 'Bagong password';

  @override
  String get newRideRequest => 'Bagong kahilingan sa biyahe';

  @override
  String get next => 'Susunod';

  @override
  String get noActiveBookingOpenTripsToViewYourHistory =>
      'Walang aktibong reserbasyon. Buksan ang Mga Biyahe para makita ang kasaysayan.';

  @override
  String get noActiveTrip => 'Walang kasalukuyang biyahe';

  @override
  String get noActiveTrips => 'Walang aktibong biyahe';

  @override
  String get noArrivalIsAwaitingConfirmation =>
      'Walang pagdating na naghihintay ng kumpirmasyon.';

  @override
  String get noBlockedDrivers => 'Walang hinaharang na drayber';

  @override
  String get noBookingsHereYet => 'Wala pang reserbasyon dito.';

  @override
  String get noBookingsInThisCategory =>
      'Walang reserbasyon sa kategoryang ito.';

  @override
  String get noCharge => 'Walang singil';

  @override
  String get noCompletedBookingsFoundForThisPeriod =>
      'Walang natapos na reserbasyon sa panahong ito.';

  @override
  String get noCompletedDriverTripsYet =>
      'Wala pang natapos na biyahe ng drayber.';

  @override
  String get noConfirmedMoneyMovementYet =>
      'Wala pang nakumpirmang transaksiyon.';

  @override
  String get noDestinationsSelected => 'Wala pang napiling destinasyon';

  @override
  String
  get noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate =>
      'Walang dagdag para sa layo, paghihintay o dami ng pasahero. Hiwalay ang entrance fee at mga binili.';

  @override
  String get noDriverAcceptedDuringThisSearchWindowRetryToOpenAFreshRequest =>
      'Walang drayber na tumanggap sa oras ng paghahanap. Subukang muli upang magbukas ng bagong kahilingan o magkansela nang walang singil.';

  @override
  String get noDriversAwaitingReview =>
      'Walang drayber na naghihintay ng pagsusuri';

  @override
  String get noDriverYet => 'Wala pang drayber';

  @override
  String get noEligibleActiveDrivers => 'Walang kwalipikadong aktibong drayber';

  @override
  String get noEndedTripsInThisPeriod =>
      'Walang natapos na biyahe sa panahong ito.';

  @override
  String get noExportRequestsYet => 'Wala pang kahilingan ng export.';

  @override
  String get noLocalRoadRouteWasReturned =>
      'Walang nakuhang ruta sa mga lokal na kalsada.';

  @override
  String get noNotificationsYet => 'Wala pang abiso';

  @override
  String get noPastTripsYet => 'Wala pang nakaraang biyahe';

  @override
  String get noPendingRequest => 'Walang Naghihintay na Kahilingan';

  @override
  String get noPhotosAvailable => 'Walang available na larawan';

  @override
  String get noRecentBookings => 'Walang kamakailang reserbasyon';

  @override
  String get noReviewsFound => 'Walang nakitang review.';

  @override
  String get noShowFee => 'Bayad sa hindi pagsipot';

  @override
  String get noSpotsFound => 'Walang nakitang pasyalan';

  @override
  String get noSystemFeedbackFound => 'Walang nakitang feedback sa sistema.';

  @override
  String get notificationDeliveryFailures => 'Mga nabigong paghahatid ng abiso';

  @override
  String get notifications => 'Mga abiso';

  @override
  String get noTouristsFound => 'Walang nakitang turista';

  @override
  String get noTouristSpotsFound => 'Walang nakitang pasyalan.';

  @override
  String get notRated => 'Wala pang rating';

  @override
  String get notVerified => 'Hindi beripikado';

  @override
  String get notYet => 'Hindi pa';

  @override
  String get nov => 'Nob';

  @override
  String get noVerifiedContactNumberIsAvailableForThisTourist =>
      'Walang beripikadong numero ng telepono para sa turistang ito.';

  @override
  String get oct => 'Okt';

  @override
  String get officialEmergencyNumbersFromMunicipalityPortal =>
      'Mga numerong pang-emerhensiya mula sa portal ng munisipyo.';

  @override
  String get offline => 'Naka-offline';

  @override
  String get offlineConnection => 'Walang koneksiyon';

  @override
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnection(
    String time,
  ) {
    return 'Offline · ipinapakita ang naka-save na datos mula $time. Kailangan ng koneksiyon para sa mahahalagang aksiyon.';
  }

  @override
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnectionValue(
    String value,
  ) {
    return 'Offline · ipinapakita ang naka-save na data mula $value. Kailangan ng koneksiyon para sa mahahalagang aksiyon.';
  }

  @override
  String get offlineSavedInformationMayBeShown =>
      'Offline · maaaring ipakita ang naka-save na impormasyon.';

  @override
  String
  get offThePlannedRouteNavigationIsRecalculatingFollowLegalLocalRoadsAndStop =>
      'Lumihis sa ruta · muling kinakalkula ang nabigasyon. Sundin ang mga legal na daan at huminto nang ligtas kung hindi sigurado.';

  @override
  String get onePriceForTheBookedRoute =>
      'Isang presyo para sa naka-book na ruta';

  @override
  String get ongoing => 'Kasalukuyan';

  @override
  String get online => 'Naka-online';

  @override
  String get onlinePayment => 'Online na pagbabayad';

  @override
  String get onlinePaymentFailedRetryAvailable =>
      'Nabigo ang online na pagbabayad — maaaring subukang muli';

  @override
  String get onlinePaymentNotStarted =>
      'Hindi pa nasisimulan ang online na pagbabayad';

  @override
  String get onlinePaymentReceived => 'Natanggap ang online na bayad';

  @override
  String get onlinePaymentRequiresTheConfiguredServer =>
      'Kailangan ang naka-configure na server para sa online na pagbabayad.';

  @override
  String get onlinePaymentsRequireAVerifiedPaymentProvider =>
      'Kailangan ng beripikadong tagapagbigay ng bayad para sa online na pagbabayad.';

  @override
  String get onlineRefundAwaitingAdminAction =>
      'Naghihintay ng aksiyon ng admin para sa online na refund';

  @override
  String get onlineRefundDue => 'Nakatakdang online na refund';

  @override
  String get onlyACompletedUnratedTripCanBeReviewed =>
      'Ang natapos na biyahe na wala pang rating lamang ang maaaring i-review.';

  @override
  String get onlyAnAcceptedBookingCanStart =>
      'Ang tinanggap na reserbasyon lamang ang maaaring simulan.';

  @override
  String get onlyAnEndedTripWithAnOpenReviewCanBeResolved =>
      'Ang natapos na biyahe na may bukas na pagsusuri lamang ang maaaring resolbahin.';

  @override
  String get onlyAnOngoingTripCanBeCompleted =>
      'Ang kasalukuyang biyahe lamang ang maaaring tapusin.';

  @override
  String get onlyAParticipantCanReportAPaymentIssue =>
      'Kalahok lamang ang maaaring mag-ulat ng problema sa bayad.';

  @override
  String get onlyAPendingDriverApplicationCanBeResumedFromThisForm =>
      'Naghihintay na aplikasyon ng drayber lamang ang maaaring ipagpatuloy sa form na ito.';

  @override
  String get onlyATripParticipantCanEndThisTrip =>
      'Kalahok lamang sa biyahe ang maaaring magtapos nito.';

  @override
  String get onlyThePayerAndReceiverCanConfirmCash =>
      'Ang nagbayad at tumanggap lamang ang maaaring magkumpirma ng cash.';

  @override
  String
  get onlyUnvisitedStopsMoveTheOtherParticipantMustApproveBeforeNavigationChanges =>
      'Mga hindi pa napupuntahang hinto lamang ang maaaring baguhin. Kailangang aprubahan ito ng kabilang panig bago baguhin ang ruta.';

  @override
  String get openAPaymentReview => 'Magbukas ng pagsusuri sa bayad';

  @override
  String get openAppStore => 'Buksan ang app store';

  @override
  String openAppToViewThisUpdate(String brandName) {
    return 'Buksan ang $brandName upang makita ang update na ito.';
  }

  @override
  String get openDialer => 'Buksan ang dialer';

  @override
  String get openDriverSearch => 'Buksan ang paghahanap ng drayber';

  @override
  String get openingHours => 'Mga Oras ng Pagbubukas';

  @override
  String openReviewsValue(String value) {
    return 'Mga bukas na pagsusuri: $value';
  }

  @override
  String get openTheMobileAppForTheInteractiveRoute =>
      'Buksan ang mobile app para sa interaktibong ruta.';

  @override
  String get openTripMap => 'Buksan ang mapa ng biyahe';

  @override
  String get openTripsToSeeTheLatestBookingStatus =>
      'Buksan ang Mga biyahe upang makita ang pinakabagong katayuan ng reserbasyon.';

  @override
  String operationalAlertSNeedReviewValue(String value) {
    return '$value alerto sa operasyon ang kailangang suriin';
  }

  @override
  String operationFailureValue(String value) {
    return 'Pagpalya ng operasyon: $value';
  }

  @override
  String get operationsCentre => 'Sentro ng operasyon';

  @override
  String get other => 'Iba pa';

  @override
  String get overview => 'Pangkalahatang-ideya';

  @override
  String get packageNotFound => 'Hindi nakita ang pakete.';

  @override
  String get packageStopsChangedSelectThePackageAgain =>
      'Nagbago ang mga hintuan ng package. Piliin muli ang package.';

  @override
  String get paid => 'Bayad na';

  @override
  String get paidOnline => 'Nabayaran online';

  @override
  String get park => 'Liwasan';

  @override
  String get partiallypaid => 'Bahagyang bayad';

  @override
  String get partiallyRefunded => 'Bahagyang na-refund';

  @override
  String get passengerCapacity => 'Kapasidad ng pasahero';

  @override
  String passengerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasahero',
      one: '1 pasahero',
    );
    return '$_temp0';
  }

  @override
  String get passengerRequirements => 'Mga pangangailangan ng pasahero';

  @override
  String get passengers => 'Mga pasahero';

  @override
  String passengersValue(String value) {
    return '$value pasahero';
  }

  @override
  String get password => 'Password';

  @override
  String get passwordIsRequired => 'Kailangan ang password';

  @override
  String get passwordMustBeAtLeast8Characters =>
      'Dapat may hindi bababa sa 8 karakter ang password';

  @override
  String get passwordMustContainAtLeastOneNumber =>
      'Dapat may kahit isang numero ang password';

  @override
  String get passwordMustContainAtLeastOneUppercaseLetter =>
      'Dapat may kahit isang malaking titik ang password';

  @override
  String passwordMustNotExceedCharactersValue(String value) {
    return 'Hindi dapat lumampas sa $value karakter ang password';
  }

  @override
  String get passwordsDoNotMatch => 'Hindi magkatugma ang mga password';

  @override
  String get passwordUpdatedSignInAgain =>
      'Napalitan na ang password. Mag-login muli.';

  @override
  String get past => 'Nakaraan';

  @override
  String get pauseForAVehicleProblem =>
      'Huminto dahil sa problema sa sasakyan?';

  @override
  String get paymentAttention => 'Kailangang asikasuhin ang bayad';

  @override
  String paymentDisputedValue(String value) {
    return 'Kinuwestiyon ang pagbabayad: $value';
  }

  @override
  String get paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr =>
      'Nakahinto muna ang pagbabayad. Kailangang suriin ng administrador ang kaso bago maningil o magsauli ng pera.';

  @override
  String
  get paymentIsPendingADriverWillOnlyBeRequestedAfterPaymentIsConfirmed =>
      'Naghihintay ng bayad. Hahanap lamang ng drayber kapag nakumpirma ang bayad. Mawawalan ng bisa ang hindi nabayarang kahilingan pagkalipas ng 30 minuto.';

  @override
  String get paymentOnHoldAdminReview =>
      'Nakahold ang bayad · sinusuri ng admin';

  @override
  String get paymentpending => 'Naghihintay ng bayad';

  @override
  String get paymentPending => 'Naghihintay ng bayad';

  @override
  String get paymentPendingLabel => 'Naghihintay ng bayad';

  @override
  String get paymentReview => 'Pagsusuri ng bayad';

  @override
  String get paymentReviewPending => 'Naghihintay ng pagsusuri ng bayad';

  @override
  String get paymentStatusCouldNotBeRefreshed =>
      'Hindi ma-refresh ang katayuan ng pagbabayad.';

  @override
  String get paymentStatusRefreshed => 'Na-refresh ang katayuan ng pagbabayad.';

  @override
  String get paymentStatusUnavailableRefreshOrUpdateTheApp =>
      'Hindi makuha ang katayuan ng pagbabayad. I-refresh o i-update ang app.';

  @override
  String get paymentVerificationRequiresTheConfiguredServer =>
      'Kailangan ang naka-configure na server upang beripikahin ang bayad.';

  @override
  String get paymongo => 'PayMongo';

  @override
  String get paymongoCheckoutReady => 'Handa na ang checkout ng PayMongo';

  @override
  String get paymongoIsProcessingPayment => 'Pinoproseso ng PayMongo ang bayad';

  @override
  String get paymongoTestModeStatusIsConfirmedByWebhookOrADirectProviderCheck =>
      'PayMongo test mode · kinukumpirma ang katayuan sa webhook o direktang pagsusuri sa provider.';

  @override
  String get paymongoUnavailable => 'Hindi available ang PayMongo';

  @override
  String get payTheFinalAmountAfterTheTripTouristAndDriverMustBothConfirm =>
      'Bayaran ang huling halaga pagkatapos ng biyahe. Dapat kumpirmahin ng turista at drayber ang pag-aabot ng cash.';

  @override
  String get pending => 'Naghihintay';

  @override
  String
  get pendingRequestsAndDriverCancellationsAreFreeTouristCancellationAfterTheGracePeriod =>
      'Walang bayad ang mga naghihintay na kahilingan at pagkansela ng drayber. Maaaring may nailathalang singil kapag turista ang nagkansela matapos ang palugit. Kailangan ng beripikadong pagdating ng drayber at kumpletong oras ng paghihintay bago ituring na hindi sumipot ang turista.';

  @override
  String get permanentlyDelete => 'Permanenteng burahin';

  @override
  String get personalInfo => 'Personal na Impormasyon';

  @override
  String get personalInformation => 'Personal na impormasyon';

  @override
  String get phone => 'Telepono';

  @override
  String get phoneNumber => 'Numero ng Telepono';

  @override
  String get phoneNumberIsRequired => 'Kailangan ang numero ng telepono';

  @override
  String get photoGallery => 'Galeriya ng larawan';

  @override
  String get photos => 'Mga larawan';

  @override
  String get pickupArrivalCanOnlyBeReportedForAnAcceptedBooking =>
      'Maaari lamang iulat ang pagdating sa sunduan para sa tinanggap na reserbasyon.';

  @override
  String get pickupArrivalHasAlreadyBeenRecorded =>
      'Naitala na ang pagdating sa sunduan.';

  @override
  String get pickupCode => 'Code sa sunduan';

  @override
  String get pickupCodeVerifiedTripStarted =>
      'Beripikado ang code sa pagsakay; nagsimula na ang biyahe.';

  @override
  String get pickupLocationPreview => 'Preview ng lokasyon ng sunduan';

  @override
  String get pickupPoint => 'Lugar ng sunduan';

  @override
  String pickupValue(String value) {
    return 'Sunduan: $value';
  }

  @override
  String get pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain =>
      'Pansamantalang naka-lock ang beripikasyon ng pagsakay. Maghintay at subukan muli.';

  @override
  String get pickupWait => 'Paghihintay sa sunduan';

  @override
  String get placeholderTheOwnerMustVerifyAndEnterANumber =>
      'Placeholder — dapat kumpirmahin at ilagay ng may-ari ang numero.';

  @override
  String get places => 'Mga lugar';

  @override
  String get placesYouSaved => 'Lugar na naka-save';

  @override
  String get planYourTrip => 'Planuhin ang biyahe';

  @override
  String get plateNumber => 'Numero ng Plaka';

  @override
  String get plateNumberIsRequired => 'Kailangan ang numero ng plaka';

  @override
  String plateNumberMustNotExceedCharactersValue(String value) {
    return 'Hindi dapat lumampas sa $value karakter ang numero ng plaka';
  }

  @override
  String platformFailureValue(String value) {
    return 'Pagpalya ng platform: $value';
  }

  @override
  String get pleaseConfirmYourPassword => 'Pakikumpirma ang iyong password';

  @override
  String get pleaseDescribeYourConcernOrSuggestionInDetail =>
      'Ilarawan nang detalyado ang iyong alalahanin o mungkahi…';

  @override
  String get pleaseEnterAtLeast20Characters =>
      'Maglagay ng hindi bababa sa 20 character.';

  @override
  String get pleaseEnterAValidEmailAddress =>
      'Maglagay ng wastong email address';

  @override
  String get pleaseEnterAValidPlateNumber =>
      'Maglagay ng wastong numero ng plaka';

  @override
  String get pleaseEnterYourStreetOrHouseNumber =>
      'Ilagay ang kalye o numero ng bahay';

  @override
  String get pleaseExplainTheIssueAtLeast5Characters =>
      'Ipaliwanag ang problema (hindi bababa sa 5 karakter).';

  @override
  String get pleaseGiveAReasonAtLeast5Characters =>
      'Magbigay ng dahilan (hindi bababa sa 5 karakter).';

  @override
  String get pleaseProvideDetailsAtLeast5Characters =>
      'Magbigay ng detalye (hindi bababa sa 5 karakter).';

  @override
  String get pleaseReviewTheCurrentPrivacyNotice =>
      'Pakisuri ang kasalukuyang abiso sa privacy';

  @override
  String get pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode =>
      'Maghintay ng limang minuto bago humiling ng panibagong code sa pagsakay.';

  @override
  String get policyPublishedExistingBookingsAreUnchanged =>
      'Nailathala na ang patakaran. Hindi nagbago ang mga kasalukuyang reserbasyon.';

  @override
  String policyVersionValue(String value) {
    return 'Bersiyon ng patakaran $value';
  }

  @override
  String get prepareExport => 'Ihanda ang export';

  @override
  String get preparePrivateAccountExports =>
      'Ihanda ang pribadong export ng account';

  @override
  String get preparingDriverRoute => 'Inihahanda ang ruta ng drayber';

  @override
  String get preparingRoute => 'Inihahanda ang ruta...';

  @override
  String get pressSosToOpenYourPhoneDialerWithTheNationalEmergencyNumber =>
      'Pindutin ang SOS upang buksan ang pantawag gamit ang pambansang numero ng emergency.';

  @override
  String get previewAnnouncement => 'I-preview ang anunsiyo';

  @override
  String priceHistoryCurrentVersionValue(String value) {
    return 'Kasaysayan ng presyo · kasalukuyang bersiyon $value';
  }

  @override
  String get pricesChangedWhileYouWereEditingReopenThisPageAndReviewTheLatest =>
      'Nagbago ang presyo habang nag-e-edit ka. Buksan muli ang pahina at suriin ang pinakabagong presyo.';

  @override
  String get priceVersion => 'Bersiyon ng presyo';

  @override
  String get privacyAndDataUse => 'Privacy at paggamit ng datos';

  @override
  String get privacyNoticeAcceptanceIsRequired =>
      'Kailangang tanggapin ang abiso sa pagkapribado.';

  @override
  String get privacyUpdate => 'Update sa Privacy';

  @override
  String get profileImagesMustBe5MbOrSmaller =>
      'Dapat 5 MB o mas maliit ang larawan ng profile.';

  @override
  String get profileImagesMustBeJpegOrPngFiles =>
      'Dapat JPEG o PNG ang larawan ng profile.';

  @override
  String get profileUpdatedSuccessfully =>
      'Matagumpay na na-update ang profile';

  @override
  String get profileUpdatedSuccessfullyLabel =>
      'Matagumpay na na-update ang profile!';

  @override
  String get proposeANewStopOrder =>
      'Magmungkahi ng bagong pagkakasunod-sunod ng mga hinto';

  @override
  String proposedValue(String value) {
    return 'Iminungkahi: $value';
  }

  @override
  String get publish => 'Ilathala';

  @override
  String get publishCancellationPolicy =>
      'Ilathala ang patakaran sa pagkansela?';

  @override
  String get publishedPolicy => 'Nailathalang patakaran';

  @override
  String get publishing => 'Inilalathala...';

  @override
  String get publishPolicy => 'Ilathala ang patakaran';

  @override
  String get publishTheseFixedFares => 'Ilathala ang mga takdang pamasahe?';

  @override
  String get radius130Km => 'Saklaw (1–30 km)';

  @override
  String get rateDriver => 'I-rate ang drayber';

  @override
  String get rating => 'Rating';

  @override
  String get ratingsFeedback => 'Mga Rating at Feedback';

  @override
  String get ratingsReviews => 'Mga rating at pagsusuri';

  @override
  String get readyForApproval => 'Handa nang aprubahan';

  @override
  String get readyMadeDaysOut => 'Handang mga biyahe';

  @override
  String get readyMadeTrips => 'Handang mga biyahe';

  @override
  String get reason => 'Dahilan';

  @override
  String get reasonAtLeast5Characters => 'Dahilan (hindi bababa sa 5 karakter)';

  @override
  String get reasonDetails => 'Dahilan / mga detalye';

  @override
  String get reasonForChangingTheOrder =>
      'Dahilan ng pagbabago ng pagkakasunod-sunod';

  @override
  String get reasonForPolicyChange => 'Dahilan ng pagbabago ng patakaran';

  @override
  String get reasonForPriceChange => 'Dahilan ng pagbabago ng presyo';

  @override
  String get receiveBookingsEarnMoneyAndShowcaseYourLocalKnowledge =>
      'Tumanggap ng mga reserbasyon, kumita at ibahagi ang iyong kaalaman sa lugar.';

  @override
  String get recentBookings => 'Mga kamakailang reserbasyon';

  @override
  String get refresh => 'I-refresh';

  @override
  String get refreshPaymentStatus => 'I-refresh ang katayuan ng bayad';

  @override
  String get refundCompleted => 'Natapos ang refund';

  @override
  String get refundCompletedInPaymongoTestMode =>
      'Natapos ang refund sa test mode ng PayMongo.';

  @override
  String get refundCompletedInTheTestPaymentEnvironment =>
      'Natapos ang refund sa test na environment ng pagbabayad.';

  @override
  String get refundDecisionRecorded => 'Naitala ang pasiya sa refund.';

  @override
  String get refunddue => 'May ibabalik na bayad';

  @override
  String get refunded => 'Naibalik na ang bayad';

  @override
  String get refundRequired => 'Kailangang ibalik ang bayad';

  @override
  String get refundSentAwaitingPaymongoConfirmation =>
      'Naipadala ang refund · naghihintay ng kumpirmasyon ng PayMongo';

  @override
  String get refundUpdateRecorded => 'Naitala ang update sa refund.';

  @override
  String get register => 'Magparehistro';

  @override
  String get registrationDidNotComplete => 'Hindi natapos ang pagpaparehistro.';

  @override
  String get reissueCode => 'Palitan ang code';

  @override
  String get reissuePickupCode => 'Palitan ang sunduan code?';

  @override
  String get reject => 'Tanggihan';

  @override
  String get rejectApplication => 'Tanggihan ang aplikasyon';

  @override
  String get rejected => 'Tinanggihan';

  @override
  String releaseConfigurationIsIncompleteValue(String value) {
    return 'Hindi kumpleto ang configuration ng release: $value';
  }

  @override
  String get reliability => 'Pagiging maaasahan';

  @override
  String reliabilitySeatsValue(String value, String secondValue) {
    return '$value% pagiging maaasahan • $secondValue upuan';
  }

  @override
  String reliableValue(String value) {
    return '$value% maaasahan';
  }

  @override
  String get removedFromYourItinerary => 'Inalis sa iyong itineraryo';

  @override
  String get removeDuplicateDestinations =>
      'Alisin ang mga naulit na destinasyon.';

  @override
  String get reopenAttraction => 'Muling buksan ang pasyalan';

  @override
  String reopenedValue(String value) {
    return 'Muling binuksan ang $value';
  }

  @override
  String get replacementNeeded => 'Kailangan ng kapalit';

  @override
  String get replacementpending => 'Naghihintay ng kapalit';

  @override
  String get replacementPending => 'Naghihintay ng kapalit';

  @override
  String get reportArrivalAtNextStop =>
      'Iulat ang pagdating sa susunod na hintuan';

  @override
  String get reports => 'Mga ulat';

  @override
  String get reportsAnalytics => 'Mga Ulat at Pagsusuri';

  @override
  String get reportTouristNoShow => 'Iulat na hindi dumating ang turista?';

  @override
  String get reportTouristNoShowLabel => 'Iulat na hindi sumipot ang turista';

  @override
  String get reportYourVerifiedArrivalAtThePickupPointBeforeStarting =>
      'Iulat ang iyong beripikadong pagdating sa sunduan bago magsimula.';

  @override
  String get requestACopyOfYourAccountAndTripDataSupportPreparesTheExport =>
      'Humiling ng kopya ng data ng iyong account at mga biyahe. Ihahanda ng support ang export para lamang sa iyong account.';

  @override
  String get requestADifferentStopOrder =>
      'Humiling ng ibang pagkakasunod-sunod ng mga hintuan';

  @override
  String get requestADriverNow => 'Humiling ng drayber ngayon';

  @override
  String get requestAnotherDriver => 'Humiling ng ibang drayber?';

  @override
  String get requestDataExport => 'Humiling ng export ng data';

  @override
  String get requestIsNoLongerPending => 'Hindi na naghihintay ang kahilingan';

  @override
  String get requests => 'Mga kahilingan';

  @override
  String get requestSaved => 'Naka-save ang kahilingan';

  @override
  String get requestToSkipThisStop => 'Humiling na laktawan ang hintuang ito';

  @override
  String requestToSkipValue(String value) {
    return 'Humiling na laktawan ang $value?';
  }

  @override
  String get resetMap => 'I-reset ang mapa';

  @override
  String get resolve => 'Lutasin';

  @override
  String get resolved => 'Nalutas';

  @override
  String get resolvePaymentReview => 'Tapusin ang pagsusuri ng bayad';

  @override
  String get resortCaf => 'Resort at café';

  @override
  String get respondToCommunityConcerns =>
      'Tumugon sa mga alalahanin ng komunidad';

  @override
  String get restore => 'Ibalik';

  @override
  String get restoreTourist => 'Ibalik ang turista?';

  @override
  String get resumePayment => 'Ipagpatuloy ang pagbabayad';

  @override
  String get retry => 'Subukan muli';

  @override
  String get retryConnection => 'Subukang kumonekta muli';

  @override
  String get retrying => 'Sinusubukang muli…';

  @override
  String get retryStorage => 'Subukan muli';

  @override
  String get retypePassword => 'I-type muli ang password';

  @override
  String get revenueOverTime => 'Kita sa Paglipas ng Panahon';

  @override
  String get review => 'Suriin';

  @override
  String get reviewActiveAndCompletedTrips =>
      'Suriin ang mga kasalukuyan at natapos na biyahe';

  @override
  String get reviewAndPublishFares => 'Suriin at ilathala ang mga pamasahe';

  @override
  String get reviewAndPublishPolicy => 'Suriin at ilathala ang patakaran';

  @override
  String get reviewCountSummary => '(128 pagsusuri)';

  @override
  String get reviewFailuresAndStaleDrivers =>
      'Suriin ang mga pagpalya at drayber na walang bagong heartbeat';

  @override
  String get reviewFare => 'Suriin ang pamasahe';

  @override
  String get reviewFlaggedForFollowUp =>
      'Minarkahan ang review para sa follow-up';

  @override
  String get reviewNote => 'Tala ng pagsusuri';

  @override
  String get reviewPendingDrivers => 'Suriin ang mga naghihintay na drayber';

  @override
  String reviewResolvedFinalChargeValue(String value, String secondValue) {
    return 'Natapos ang pagsusuri: ₱$value ang huling singil. $secondValue';
  }

  @override
  String get reviews => 'Mga review';

  @override
  String get reviewYourBooking => 'Suriin ang reserbasyon mo';

  @override
  String get ride => 'Sakay';

  @override
  String get rideAndBookingUpdates => 'Mga update sa sakay at reserbasyon';

  @override
  String get rideUpdates => 'Mga update sa sakay';

  @override
  String get roadRouteUnavailableCheckYourConnectionAndTryAgain =>
      'Hindi makuha ang ruta. Suriin ang koneksiyon at subukan muli.';

  @override
  String routeProgressConfirmedValue(String value, String secondValue) {
    return 'Pag-usad sa ruta · $value/$secondValue ang nakumpirma';
  }

  @override
  String get routeReorderApprovalNeeded =>
      'Kailangan ang pag-apruba sa pagbabago ng ruta';

  @override
  String get safeCapacity => 'Ligtas na kapasidad';

  @override
  String get safeDriver => 'Ligtas na drayber';

  @override
  String get safePassengerCapacity => 'Ligtas na kapasidad ng pasahero';

  @override
  String get safetySupport => 'Kaligtasan at suporta';

  @override
  String get sanPedro => 'San pedro';

  @override
  String get sat => 'Sab';

  @override
  String get saveChanges => 'I-save ang mga Pagbabago';

  @override
  String get saved => 'Naka-save';

  @override
  String get saveDecision => 'I-save ang pasya';

  @override
  String get savedPlaces => 'Mga paborito';

  @override
  String get savedTripDataCouldNotBeReadBookingChangesArePausedToProtect =>
      'Hindi mabasa ang naka-save na biyahe. Pansamantalang inihinto ang pagbabago ng reserbasyon upang protektahan ang iyong mga tala. Subukan muli ang storage o i-restart ang app.';

  @override
  String get saveFailed => 'Hindi na-save';

  @override
  String get savePlacesYouLove => 'I-save ang mga lugar na gusto mo';

  @override
  String get saveReviewWithoutApproval =>
      'I-save ang pagsusuri nang walang pag-apruba';

  @override
  String get saveSpot => 'I-save ang Pasyalan';

  @override
  String get saving => 'Sine-save…';

  @override
  String get savingBooking => 'Sine-save ang reserbasyon…';

  @override
  String get scheduled => 'Naka-iskedyul';

  @override
  String get scheduledFor => 'Naiskedyul para sa';

  @override
  String get scheduledJobFailures => 'Mga nabigong nakaiskedyul na gawain';

  @override
  String get scheduledPickup => 'Naiskedyul na sunduan';

  @override
  String get schedulePickupAtLeast1HourFromNow =>
      'Pumili ng sunduan na hindi bababa sa isang oras mula ngayon.';

  @override
  String get search => 'Maghanap';

  @override
  String get searchAgain => 'Maghanap muli';

  @override
  String get searchDrivers => 'Maghanap ng drayber';

  @override
  String get searchSpots => 'Maghanap ng mga pasyalan…';

  @override
  String get searchWindowEnded => 'Natapos ang oras ng paghahanap';

  @override
  String get secureYourAccount => 'Protektahan ang account mo';

  @override
  String get seeAll => 'Tingnan lahat';

  @override
  String get seeYourDailyTripSummary =>
      'Tingnan ang buod ng iyong araw-araw na biyahe';

  @override
  String get selectAddress => 'Pumili ng address';

  @override
  String get selectARatingBetween1And5 => 'Pumili ng rating mula 1 hanggang 5.';

  @override
  String get selectAtLeastOneDestinationFirst =>
      'Pumili muna ng kahit isang destinasyon.';

  @override
  String get selectBetween1And12Destinations =>
      'Pumili ng 1 hanggang 12 destinasyon.';

  @override
  String get selectedStop => 'Napiling hintuan';

  @override
  String get selectExpiryDate => 'Piliin ang petsa ng pag-expire';

  @override
  String get sendAnAnnouncement => 'Magpadala ng anunsiyo';

  @override
  String get sendAnnouncement => 'Magpadala ng Anunsiyo';

  @override
  String get sendASupportMessage => 'Magpadala ng mensahe para sa suporta';

  @override
  String get sendFeedback => 'Magpadala ng feedback';

  @override
  String get sendProposal => 'Ipadala ang mungkahi';

  @override
  String get sendRefundRequestToPaymongo =>
      'Ipadala ang kahilingan sa refund sa PayMongo';

  @override
  String get sendRefundToPaymongo => 'Ipadala ang refund sa PayMongo?';

  @override
  String get sendResetLink => 'Ipadala ang Reset Link';

  @override
  String get sep => 'Set';

  @override
  String get serverSetupIsIncomplete =>
      'Hindi pa kumpleto ang pagkakakonekta sa server.';

  @override
  String
  get serverSetupIsIncompleteAddTheSupabaseBuildConfigurationBeforeSigningIn =>
      'Hindi kumpleto ang pag-setup ng server. Idagdag ang configuration ng Supabase bago mag-sign in.';

  @override
  String get serverSetupIsIncompleteFeedbackWasNotSent =>
      'Hindi kumpleto ang pag-setup ng server. Hindi naipadala ang feedback.';

  @override
  String get serverSetupIsIncompleteNothingWasSent =>
      'Hindi kumpleto ang pag-setup ng server. Walang naipadala.';

  @override
  String get serverSetupIsIncompleteTheAttractionWasNotSaved =>
      'Hindi kumpleto ang pag-setup ng server. Hindi na-save ang pasyalan.';

  @override
  String serviceAreaValue(String value) {
    return 'Lugar ng serbisyo: $value ';
  }

  @override
  String get serviceHealth => 'Kalagayan ng serbisyo';

  @override
  String get sessionChanged => 'Nagbago ang session.';

  @override
  String get setAFlatCustomTourFareAndAFixedFareForEachPackage =>
      'Magtakda ng isang pamasahe para sa pasadyang tour at bawat package. Walang awtomatikong dagdag para sa hintuan, distansiya, paghihintay o dagsa ng pasahero. Hiwalay ang bayad sa pagpasok.';

  @override
  String get shareAnUpdateWithDriversOrTourists =>
      'Magbahagi ng update sa mga drayber o turista';

  @override
  String get shareThisCodeOnlyWhenYouAreOnBoard =>
      'Ibigay lamang ang code na ito kapag nakasakay ka na';

  @override
  String get sharingLocation => 'Ibinabahagi ang lokasyon';

  @override
  String showValue(String value) {
    return 'Ipakita ang $value';
  }

  @override
  String get signInAfterConfirmingYourEmail =>
      'Mag-sign in pagkatapos kumpirmahin ang iyong email.';

  @override
  String get signInBeforeSendingFeedback =>
      'Mag-sign in bago magpadala ng feedback.';

  @override
  String get signInFirst => 'Mag-sign in muna.';

  @override
  String get signOut => 'Mag-sign out';

  @override
  String get signUp => 'Mag-sign Up';

  @override
  String get skip => 'Laktawan';

  @override
  String
  get someInformationCouldNotRefreshPreviouslyLoadedDataIsShownReconnectAndRetry =>
      'May impormasyong hindi ma-refresh. Ipinapakita ang dating na-load na datos; kumonekta at subukang muli.';

  @override
  String get sos => 'SOS';

  @override
  String get spotName => 'Pangalan ng Pasyalan';

  @override
  String get spots => 'mga lugar';

  @override
  String get staleOnlineDrivers =>
      'Mga online na drayber na walang bagong heartbeat';

  @override
  String get startNewSearch => 'Magsimula ng bagong paghahanap';

  @override
  String statusValue(String value) {
    return 'Katayuan: $value';
  }

  @override
  String get stillToPay => 'Dapat pang bayaran';

  @override
  String get stop => 'Hintuan';

  @override
  String get stopAtASafePlaceFirstTheTripWillEndImmediatelyPaymentWill =>
      'Huminto muna sa ligtas na lugar. Agad na matatapos ang biyahe. Ihahold ang bayad para sa pagsusuri ng admin; hindi maaaring awtomatikong singilin ng alinmang panig ang buong pamasahe. Ilarawan ang nangyari, tulad ng pagbabago ng plano, pagkasira ng sasakyan, panganib o pagsara ng pasyalan.';

  @override
  String stopCustomTourValue(String value) {
    return 'Pasadyang tour na may $value hintuan';
  }

  @override
  String get stops => 'stops';

  @override
  String get stopsIncluded => 'Mga kasamang hintuan';

  @override
  String get stopSkipApprovalNeeded =>
      'Kailangan ang pag-apruba sa paglaktaw ng hintuan';

  @override
  String
  get stopSomewhereSafeFirstYourCurrentGpsLocationAndExplanationWillBeRecorded =>
      'Huminto muna sa ligtas na lugar. Itatala ang kasalukuyang lokasyon sa GPS at iyong paliwanag. Maaaring maghintay ang turista o tapusin ang paglilibot para masuri ang bayad.';

  @override
  String stopsValue(String value) {
    return '$value hintuan';
  }

  @override
  String stopsValueLabel(String value, String secondValue) {
    return '$value hintuan • ₱$secondValue';
  }

  @override
  String get stopTemporarilyUnavailable =>
      'Pansamantalang hindi available ang hintuan';

  @override
  String stopValue(String value) {
    return 'Hintuan: $value';
  }

  @override
  String get storageIsUnavailableRetryStorageBeforeMakingChanges =>
      'Hindi available ang storage. Subukan muli ito bago gumawa ng pagbabago.';

  @override
  String get storeUnavailable => 'Hindi mabuksan ang app store';

  @override
  String get streetHouseNo => 'Kalye / numero ng bahay';

  @override
  String get streetNameBuildingHouseNo =>
      'Pangalan ng kalye, gusali, numero ng bahay';

  @override
  String get submit => 'Ipadala';

  @override
  String get submitApplication => 'Isumite ang aplikasyon';

  @override
  String get submitFeedback => 'Ipadala ang feedback';

  @override
  String get submitReview => 'Ipadala ang pagsusuri';

  @override
  String get submittedDocuments => 'Mga naisumiteng dokumento';

  @override
  String get sun => 'Lin';

  @override
  String get supportSettings => 'Suporta at setting';

  @override
  String get suspend => 'Suspindihin';

  @override
  String get suspendDriver => 'Suspindihin ang drayber';

  @override
  String get suspended => 'Sinuspinde';

  @override
  String get suspendTourist => 'Suspindihin ang turista?';

  @override
  String get suspendTouristLabel => 'Suspindihin ang Turista';

  @override
  String suspendValue(String value) {
    return 'Suspindihin si $value';
  }

  @override
  String get systemActionsAreUnavailableHere =>
      'Hindi available dito ang mga aksiyon ng sistema.';

  @override
  String get systemFeedback => 'Feedback sa Sistema';

  @override
  String get tapTheHeartOnAnyTouristSpotToKeepItHere =>
      'I-tap ang puso sa pasyalan upang itabi ito rito.';

  @override
  String get tellUsWhatToImprove => 'Sabihin kung ano ang dapat pagandahin';

  @override
  String get temporarilyCloseAttraction => 'Pansamantalang isara ang pasyalan';

  @override
  String get temporarilyClosed => 'Pansamantalang sarado';

  @override
  String temporarilyClosedValue(String value) {
    return 'Pansamantalang isinara ang $value';
  }

  @override
  String get thankYouForYourFeedback => 'Salamat sa iyong feedback!';

  @override
  String
  get thatPickupCodeIsIncorrectOrTemporarilyLockedAfterRepeatedAttempts =>
      'Mali ang code sa pagsakay o pansamantalang naka-lock matapos ang paulit-ulit na pagsubok.';

  @override
  String get theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests =>
      'Nakapirmi ang napagkasunduang pamasahe; walang dagdag dahil sa dami ng pasahero. Walang bayad ang mga naghihintay na kahilingan at pagkansela ng drayber. Kapag tinanggap ng drayber, may maikling palugit ang turista bago maaaring singilin ng nailathalang bayad sa pagkansela. Pagkasundo, ligtas munang huminto at susuriin ng admin ang naibigay na serbisyo at ebidensiya. Hiwalay ang entrance fee at mga personal na bilihin.';

  @override
  String get theAssignedDriverIsUnavailable =>
      'Hindi available ang nakatalagang drayber.';

  @override
  String get theBookingWillEndWithoutACancellationChargeIfAnOnlinePaymentWas =>
      'Matatapos ang reserbasyon nang walang singil sa pagkansela. Kung natanggap na ang online na bayad, mamarkahan ito para sa refund.';

  @override
  String
  get theCheckoutAddressCouldNotBeVerifiedRefreshThisBookingBeforePaying =>
      'Hindi maberipika ang address ng pahina ng bayad. I-refresh ang reserbasyon bago magbayad.';

  @override
  String
  get theDriverMovedAwayFromThePlannedRouteAndNavigationWasRecalculatedLive =>
      'Lumayo ang drayber sa nakaplanong ruta kaya muling kinalkula ang nabigasyon. Aktibo pa rin ang live na pagsubaybay.';

  @override
  String get theDriverReportedAVehicleProblem =>
      'Nag-ulat ang drayber ng problema sa sasakyan.';

  @override
  String get theDriverWillFollowTheSelectedPinConfirmThatItMatchesTheAddress =>
      'Susundan ng drayber ang napiling pin. Kumpirmahing tumutugma ito sa inilagay mong address.';

  @override
  String get theFinalChargeMustBeBetweenZeroAndTheAgreedFare =>
      'Dapat nasa pagitan ng sero at napagkasunduang pamasahe ang huling singil.';

  @override
  String get theFinalChargeMustBeSettledBeforeConfirmingCash =>
      'Dapat matukoy ang huling singil bago kumpirmahin ang cash.';

  @override
  String get theFinancialRecordRequiresTheConfiguredServer =>
      'Kailangan ang naka-configure na server para sa talang pinansiyal.';

  @override
  String get theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd =>
      'Luma o hindi wasto ang posisyon ng GPS. Maghintay ng bagong signal at subukan muli.';

  @override
  String get theInteractiveOperationsMapIsAvailableInTheMobileApp =>
      'Available ang interaktibong mapa ng operasyon sa mobile app.';

  @override
  String
  get theOtherParticipantMustApproveIfApprovedFinalPaymentWillBeHeldFor =>
      'Kailangan ang pag-apruba ng kabilang panig. Kapag naaprubahan, ihahold ang huling bayad para sa patas na pagsusuri ng admin dahil nagbago ang rutang naibigay.';

  @override
  String get theOwnerMustVerifyLocalAgencyNumbersBeforeEnablingCalls =>
      'Dapat kumpirmahin ng may-ari ang mga numero ng lokal na ahensiya bago payagan ang pagtawag.';

  @override
  String get thePickupPinIsOutsideTheServiceAreaChooseANearbyPickupPoint =>
      'Nasa labas ng lugar ng serbisyo ang pin ng sunduan. Pumili ng malapit na sunduan.';

  @override
  String get thePickupPinIsOutsideTheServiceAreaChooseAnotherPickupPoint =>
      'Nasa labas ng lugar ng serbisyo ang pin ng sunduan. Pumili ng ibang sunduan.';

  @override
  String get thePickupWaitingPeriodHasNotFinished =>
      'Hindi pa tapos ang oras ng paghihintay sa sunduan.';

  @override
  String get thePolicyChangedWhileYouWereEditingReopenThisPage =>
      'Nagbago ang patakaran habang nag-e-edit ka. Buksan muli ang pahina.';

  @override
  String get thePriceChangedReviewTheUpdatedFareAndConfirmAgain =>
      'Nagbago ang presyo. Suriin ang bagong pamasahe at kumpirmahin muli.';

  @override
  String get thereAreNoRegisteredTouristsYet =>
      'Wala pang nakarehistrong turista.';

  @override
  String get thereIsNoOpenReviewOnThisBooking =>
      'Walang bukas na pagsusuri para sa reserbasyon na ito.';

  @override
  String get thereIsNoOutstandingAmountToConfirm =>
      'Walang natitirang halagang kailangang kumpirmahin.';

  @override
  String get theRideRequestIsNoLongerAvailable =>
      'Hindi na available ang kahilingan sa biyahe.';

  @override
  String get theServerIsNotConfiguredOnThisBuildAddTheSupabaseUrlAnd =>
      'Hindi pa na-configure ang server sa build na ito. Ilagay ang Supabase URL at publishable key, pagkatapos ay buuin muli ang app.';

  @override
  String get theTouristMustConfirmAllBookedStopsUseEndTourEarlyForAn =>
      'Dapat kumpirmahin ng turista ang lahat ng naka-book na hintuan. Gamitin ang Maagang tapusin ang tour para sa hindi nakumpletong ruta.';

  @override
  String thisAccountBelongsToThePortal(String role) {
    return 'Para sa portal ng $role ang account na ito.';
  }

  @override
  String thisAccountBelongsToThePortalValue(String value) {
    return 'Para sa portal na $value ang account na ito.';
  }

  @override
  String get thisAccountCannotSignIn =>
      'Hindi makapag-sign in ang account na ito.';

  @override
  String get thisAccountHasAnInvalidRole =>
      'Hindi wasto ang tungkulin ng account na ito.';

  @override
  String get thisAccountIsNotCurrentlyAllowedToSignIn =>
      'Hindi kasalukuyang pinapayagang mag-sign in ang account na ito.';

  @override
  String get thisAccountIsStillAwaitingAdministratorApproval =>
      'Naghihintay pa ng pag-apruba ng administrador ang account na ito.';

  @override
  String
  get thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd =>
      'Hindi makumpleto ang aksiyong ito. Nananatili ang iyong mga tala. I-refresh at subukan muli.';

  @override
  String get thisAttractionBelongsToATourPackageHideItInsteadOfDeletingIt =>
      'Kasama ang pasyalang ito sa isang tour package. Itago ito sa halip na burahin.';

  @override
  String get thisAttractionIsInAnActiveBookingHideItForNewTripsInstead =>
      'Kasama ang pasyalang ito sa aktibong reserbasyon. Itago ito para sa mga bagong biyahe.';

  @override
  String get thisAttractionIsNoLongerAvailable =>
      'Hindi na available ang pasyalang ito.';

  @override
  String get thisBookingBelongsToAnotherTourist =>
      'Pagmamay-ari ng ibang turista ang reserbasyon na ito.';

  @override
  String get thisBookingCouldNotBeFound =>
      'Hindi makita ang reserbasyon na ito.';

  @override
  String get thisBookingIsAlreadyUnderReviewAddYourStatementToTheCase =>
      'Sinusuri na ang reserbasyon na ito. Idagdag ang iyong pahayag sa kaso.';

  @override
  String get thisBookingIsAssignedToAnotherDriver =>
      'Nakatakda sa ibang drayber ang reserbasyon na ito.';

  @override
  String get thisBookingRequestIsNotReadyToRetry =>
      'Hindi pa maaaring subukang muli ang kahilingan ng reserbasyon na ito.';

  @override
  String get thisCancellationIsCurrentlyFreeGiveTheRealReasonSoTheEventCan =>
      'Wala pang singil sa pagkanselang ito. Ibigay ang tunay na dahilan upang masuri ang tala.';

  @override
  String
  get thisCompletesTheRefundWorkflowForThePaymongoTestTransactionRecordsTheResult =>
      'Tatapusin nito ang proseso ng refund para sa test na transaksiyon ng PayMongo, itatala ang resulta at aabisuhan ang turista. Ilagay ang dahilan ng refund.';

  @override
  String get thisDriverAccountIsStillAwaitingAdministratorApproval =>
      'Naghihintay pa ng pag-apruba ng administrador ang account ng drayber na ito.';

  @override
  String get thisField => 'Ang field na ito';

  @override
  String get thisMonth => 'Ngayong buwan';

  @override
  String get thisOpensYourPhoneDialerConfirmTheNumberBeforeCalling =>
      'Bubuksan nito ang dialer ng telepono. Kumpirmahin ang numero bago tumawag.';

  @override
  String get thisOpensYourPhoneDialerWith911YouMustPressCallToContact =>
      'Bubuksan nito ang dialer na may numerong 911. Pindutin ang Tumawag para makontak ang serbisyong pang-emerhensiya.';

  @override
  String get thisPackageCannotBeBookedUntilAllStopsAreAvailable =>
      'Hindi maaaring ipareserba ang paketeng ito hangga’t hindi available ang lahat ng hintuan.';

  @override
  String get thisPackageHasAFixedRouteTheStopsAreAlreadySelectedForYou =>
      'May nakapirming ruta ang paketeng ito. Napili na ang mga hintuan para sa iyo.';

  @override
  String get thisPackageHasNoPublishedPrice =>
      'Wala pang nailathalang presyo ang paketeng ito.';

  @override
  String get thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne =>
      'Hindi wasto o expired na ang link sa pagpapalit ng password. Humiling ng bago.';

  @override
  String get thisPickupPinIsOutsideTheServiceAreaMoveThePinCloserTo =>
      'Nasa labas ng lugar ng serbisyo ang pin sa sunduan. Ilapit ito sa sentro ng serbisyo.';

  @override
  String
  get thisRemovesYourLoginProfileDetailsDocumentsAndAvatarsRetainedTripAndFinancial =>
      'Aalisin nito ang iyong login, detalye ng profile, mga dokumento at larawan ng profile. Ihihiwalay sa iyong pagkakakilanlan ang mga pinanatiling tala ng biyahe at pananalapi. Tapusin o kanselahin muna ang aktibong reserbasyon. I-type ang DELETE upang kumpirmahin.';

  @override
  String get thisRequestAlreadyExistsRefreshYourTripsBeforeTryingAgain =>
      'May ganitong kahilingan na. I-refresh ang mga biyahe bago subukang muli.';

  @override
  String get thisRequestIsNoLongerAvailable =>
      'Hindi na available ang kahilingang ito.';

  @override
  String get thisSendsTheExactAmountToPaymongoAndRecordsOnlyTheProviderResult =>
      'Ipapadala nito ang eksaktong halaga sa PayMongo at itatala lamang ang resulta ng provider. Kasalukuyang para lamang sa live na transaksiyon ang aktuwal na refund ng PayMongo, kaya mananatiling malinaw na hindi na-refund ang pagtanggi sa test mode. Ilagay ang dahilan ng pasiya.';

  @override
  String get thisTouristAccountCannotBookRightNowContactTheAdministrator =>
      'Hindi makapag-book ang account ng turistang ito ngayon. Makipag-ugnayan sa administrador.';

  @override
  String get thisTouristAccountIsCurrentlyUnavailable =>
      'Hindi kasalukuyang available ang account ng turistang ito.';

  @override
  String get thisTripCouldNotBeFoundOrHasBeenRemoved =>
      'Hindi makita o naalis na ang biyaheng ito.';

  @override
  String get thisTripHasAlreadyEnded => 'Natapos na ang biyaheng ito.';

  @override
  String get thisTripIsNotInProgress =>
      'Hindi kasalukuyang tumatakbo ang biyaheng ito.';

  @override
  String get thisTripUsesANewerStatusUpdateTheAppOrContactSupportBefore =>
      'Gumagamit ang biyaheng ito ng mas bagong katayuan. I-update ang app o kontakin ang support bago gumawa ng pagbabago.';

  @override
  String get thisWeek => 'Ngayong linggo';

  @override
  String get thisYear => 'Ngayong taon';

  @override
  String threeLineSummary(String value, String secondValue, String thirdValue) {
    return '$value · $secondValue\n$thirdValue';
  }

  @override
  String get thu => 'Huw';

  @override
  String get tipsReminders => 'Mga tip at paalala';

  @override
  String get title => 'Pamagat';

  @override
  String get today => 'Ngayon';

  @override
  String get totalBookings => 'Kabuuang reserbasyon';

  @override
  String get totalFare => 'Kabuuang pamasahe';

  @override
  String get totalRevenue => 'Kabuuang kita';

  @override
  String get tourEndedEarlyPaymentHeldForReview =>
      'Maagang tinapos ang biyahe; nakahold ang bayad para sa pagsusuri';

  @override
  String get tourist => 'Turista';

  @override
  String get touristAccountActivated => 'Na-activate ang account ng turista';

  @override
  String get touristAccounts => 'Mga account ng turista';

  @override
  String get touristAccountSuspended => 'Nasuspinde ang account ng turista';

  @override
  String get touristAndDriverPolicyTerms =>
      'Mga tuntunin para sa turista at drayber';

  @override
  String touristConfirmedStopValue(String value) {
    return 'Kinumpirma ng turista ang hintuang $value.';
  }

  @override
  String get touristNoShowAfterVerifiedPickupWait =>
      'Hindi sumipot ang turista matapos ang beripikadong paghihintay.';

  @override
  String get touristReportedAsANoShowAfterTheVerifiedWaitingPeriodPublishedNo =>
      'Iniulat na hindi sumipot ang turista matapos ang beripikadong paghihintay. Inilapat ang nakalathalang bayad.';

  @override
  String get tourists => 'Mga turista';

  @override
  String get touristsAndDrivers => 'Mga turista at drayber';

  @override
  String get touristSpot => 'Lugar ng Turista';

  @override
  String get touristSpotCreated => 'Nalikha ang pasyalan';

  @override
  String get touristSpotIssue => 'Problema sa pasyalan';

  @override
  String get touristSpots => 'Mga pasyalan';

  @override
  String get touristSpotUpdated => 'Na-update ang pasyalan';

  @override
  String touristVisibilityValue(String value) {
    return 'Pagpapakita ng $value sa mga turista';
  }

  @override
  String get tourPackage => 'Pakete ng paglilibot';

  @override
  String get tourPackages => 'Mga tour package';

  @override
  String get tourScheduled => 'Naiskedyul ang paglilibot';

  @override
  String get tricycleBooking => 'reserbasyon ng Traysikel';

  @override
  String get trip => 'Biyahe';

  @override
  String get tripCompletedFixedFareDueCashNotYetConfirmed =>
      'Natapos ang biyahe. Dapat bayaran ang takdang pamasahe; hindi pa kumpirmado ang cash.';

  @override
  String get tripControls => 'Mga kontrol ng biyahe';

  @override
  String get tripHistory => 'Kasaysayan ng biyahe';

  @override
  String get tripOngoing => 'Kasalukuyang bumiyahe';

  @override
  String tripPausedOpenTripControlsToChooseWhetherToWaitOrEndSafelyValue(
    String value,
  ) {
    return 'Nakahinto ang biyahe: $value. Buksan ang mga kontrol ng biyahe upang pumiling maghintay o ligtas na tapusin ito.';
  }

  @override
  String get tripPausedVehicleProblem =>
      'Nakahinto ang biyahe · may problema sa sasakyan';

  @override
  String get tripPayment => 'Biyahe at bayad';

  @override
  String get trips => 'Mga biyahe';

  @override
  String tripsValue(String value) {
    return 'Mga biyahe: $value';
  }

  @override
  String get tripUpdates => 'Mga update sa biyahe';

  @override
  String get tryAdjustingYourFiltersOrSearchTerm =>
      'Subukang baguhin ang mga filter o salitang hinahanap.';

  @override
  String get tue => 'Mar';

  @override
  String get turnByTurnMappingIsAvailableInTheMobileApp =>
      'Available ang detalyadong direksiyon sa mobile app.';

  @override
  String get turnOnGpsToShareYourLocation =>
      'I-on ang GPS upang ibahagi ang iyong lokasyon.';

  @override
  String get turnOnLocationServicesToUseYourCurrentPosition =>
      'I-on ang serbisyo ng lokasyon upang magamit ang kasalukuyang posisyon.';

  @override
  String twoPartDetails(String value, String secondValue) {
    return '$value • $secondValue';
  }

  @override
  String twoPartSummary(String value, String secondValue) {
    return '$value · $secondValue';
  }

  @override
  String get unableToCheckAppRequirements =>
      'Hindi masuri ang mga kinakailangan ng app';

  @override
  String get unableToLoadThePrivacyNotice =>
      'Hindi ma-load ang abiso sa privacy';

  @override
  String get unavailable => 'Hindi available';

  @override
  String get underreview => 'Sinusuri';

  @override
  String get underReview => 'Sinusuri';

  @override
  String get unknown => 'Hindi alam';

  @override
  String get unknownApplicationEnvironment =>
      'Hindi kilalang environment ng app.';

  @override
  String get unknownUntilManuallyReopened =>
      'Hindi alam / hanggang manu-manong buksan';

  @override
  String get unpaid => 'Hindi pa bayad';

  @override
  String get unsettledCash => 'Hindi pa bayad na cash';

  @override
  String get unsupportedOfflineCommand =>
      'Hindi suportado ang aksiyong ito habang offline.';

  @override
  String updateAppBeforeContinuingToUseBookingAndPaymentServices(
    String brandName,
  ) {
    return 'I-update ang $brandName bago patuloy na gumamit ng reserbasyon at pagbabayad.';
  }

  @override
  String get updateApplication => 'I-update ang aplikasyon';

  @override
  String updatedSAgoValue(String value) {
    return 'na-update ${value}s ang nakalipas';
  }

  @override
  String get updatePassword => 'Palitan ang password';

  @override
  String get updateRequired => 'Kailangan ng update';

  @override
  String get updateYourDriverDetails =>
      'I-update ang iyong detalye bilang drayber';

  @override
  String get updatingRoute => 'Ina-update ang ruta…';

  @override
  String get uploadImage => 'Mag-upload ng Larawan';

  @override
  String get uploading => 'Ina-upload…';

  @override
  String uploadValue(String value) {
    return 'I-upload ang $value';
  }

  @override
  String get useAtLeast8Characters => 'Gumamit ng hindi bababa sa 8 character';

  @override
  String get useAtLeastEightCharactersAvoidAPasswordYouUseOnAnotherService =>
      'Gumamit ng hindi bababa sa walong karakter. Iwasang gamitin ang password mo sa ibang serbisyo.';

  @override
  String get useLettersSpacesHyphensApostrophesOrPeriodsInYourName =>
      'Gumamit ng mga titik, puwang, gitling, kudlit o tuldok sa pangalan';

  @override
  String get useMyCurrentLocation => 'Gamitin ang kasalukuyan kong lokasyon';

  @override
  String get useNow => 'Gamitin ngayon';

  @override
  String get useThisOnlyIfYouCannotCompleteThePickupTheTouristWillDecide =>
      'Gamitin lamang ito kung hindi mo maitutuloy ang pagsundo. Magpapasiya ang turista kung maghahanap ng ibang beripikadong drayber o magkakansela nang walang singil. Ipaliwanag ang nangyari.';

  @override
  String get vehicleAndReliability => 'Sasakyan at pagiging maaasahan';

  @override
  String get vehicleImageSelected => 'Napili na ang larawan ng sasakyan';

  @override
  String get vehicleInfo => 'Impormasyon ng Sasakyan';

  @override
  String get vehicleInspection => 'Inspeksiyon ng sasakyan';

  @override
  String get vehicleInspectionExpiresOn => 'vehicle_inspection_expires_on';

  @override
  String vehicleInspectionValue(String value) {
    return 'Inspeksiyon ng sasakyan: $value';
  }

  @override
  String get vehicleIsSafeResumeTrip =>
      'Ligtas na ang sasakyan · ipagpatuloy ang biyahe';

  @override
  String get vehicleProblem => 'problema sa sasakyan';

  @override
  String get vehicleProblemPauseTripSafely =>
      'Problema sa sasakyan · ligtas na huminto';

  @override
  String get verificationStatus => 'Katayuan ng beripikasyon';

  @override
  String get verified => 'Beripikado';

  @override
  String verifiedAppDriver(String brandName) {
    return 'Beripikadong drayber ng $brandName';
  }

  @override
  String get verifiedNearThePickupPoint => 'Beripikadong malapit sa sunduan';

  @override
  String get verifiedPickupArrivalIsRequiredBeforeReportingANoShow =>
      'Kailangan ang beripikadong pagdating sa sunduan bago mag-ulat ng hindi pagsipot.';

  @override
  String get verifiedTourist => 'Na-verify na turista';

  @override
  String get verifyLocalAgencyNumbers =>
      'Beripikahin ang mga numero ng lokal na ahensiya';

  @override
  String get verifyPickup => 'Beripikahin ang pagsakay';

  @override
  String get verifyPickupCodeStart =>
      'Beripikahin ang code sa sunduan at magsimula';

  @override
  String get viewActiveDriversOnTheMap =>
      'Tingnan ang mga aktibong drayber sa mapa';

  @override
  String get viewAll => 'Tingnan lahat';

  @override
  String get viewAndManageTouristAccounts =>
      'Tingnan at pamahalaan ang mga account ng turista';

  @override
  String get viewBookingRequests => 'Tingnan ang mga kahilingan ng reserbasyon';

  @override
  String get viewDetails => 'Tingnan ang mga detalye';

  @override
  String get viewMap => 'Tingnan sa mapa';

  @override
  String get viewMyTrips => 'Tingnan ang aking mga biyahe';

  @override
  String get viewScheduledBooking => 'Tingnan ang nakaiskedyul na reserbasyon';

  @override
  String viewValue(String value) {
    return 'Tingnan ang $value';
  }

  @override
  String get visible => 'Nakikita';

  @override
  String get visibleToTourists => 'Nakikita ng mga Turista';

  @override
  String get waitForTheMobileMapToLoadBeforeConfirmingAnExactPickupPin =>
      'Hintaying ma-load ang mobile na mapa bago kumpirmahin ang eksaktong pin sa sunduan.';

  @override
  String get waitForTheTouristToConfirmThisStop =>
      'Hintaying kumpirmahin ng turista ang hintuang ito.';

  @override
  String get waitForThisDriver => 'Hintayin ang drayber na ito';

  @override
  String get waitingForADriverToAcceptYouCanLeaveThisPageAndResume =>
      'Naghihintay ng drayber na tatanggap. Maaari mong balikan ang reserbasyon sa Mga Biyahe.';

  @override
  String get waitingForAnApprovedDriverToAcceptYourRequest =>
      'Naghihintay ng aprubadong drayber na tatanggap sa iyong kahilingan.';

  @override
  String get waitingForCashReturnConfirmation =>
      'Naghihintay ng kumpirmasyon sa pagsasauli ng cash';

  @override
  String get waitingForLiveLocation => 'Naghihintay ng live location';

  @override
  String get waitingForTheOtherCashConfirmation =>
      'Naghihintay ng kumpirmasyon ng kabilang panig sa cash';

  @override
  String get waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute =>
      'Hinihintay ang kabilang panig. Mananatili muna sa kasalukuyang ruta.';

  @override
  String get waitingForTheTouristSDecision =>
      'Naghihintay ng pasiya ng turista.';

  @override
  String get waitingForTheTouristToChooseDoNotProceedToPickup =>
      'Hinihintay ang pasya ng turista. Huwag munang pumunta sa sunduan.';

  @override
  String get waitingPeriodCompleted => 'Natapos ang oras ng paghihintay';

  @override
  String get waived => 'Walang singil';

  @override
  String get wed => 'Miy';

  @override
  String get weHaveSentPasswordRecoveryInstructionsToYourEmail =>
      'Ipinadala na namin sa email mo ang mga tagubilin sa pagpapalit ng password.';

  @override
  String get welcomeBack => 'Maligayang pagbabalik';

  @override
  String get weLlSendNearbyBookingsYourWay =>
      'Ipapadala namin sa iyo ang mga kalapit na reserbasyon.';

  @override
  String get weWillRemindYouAndStartMatching30MinutesBeforePickup =>
      'Ipapaalala namin ang biyahe at magsisimulang maghanap ng drayber 30 minuto bago ang sunduan.';

  @override
  String get whatDidYouLikeOrDislike =>
      'Ano ang nagustuhan o hindi mo nagustuhan?';

  @override
  String get whatSIncluded => 'Ano ang kasama';

  @override
  String get whenYouGetNotificationsTheyWillAppearHere =>
      'Dito makikita ang mga abisong matatanggap mo.';

  @override
  String get whereWouldYouLikeToGo => 'Saan mo gusto pumunta?';

  @override
  String willBeCompletedInThePaymongoTestEnvironmentValue(String value) {
    return 'Tatapusin ang $value sa test environment ng PayMongo.';
  }

  @override
  String get youAlreadyHaveAnActiveBookingOpenTripsToContinueOrCancelIt =>
      'May aktibong reserbasyon ka na. Buksan ang Mga Biyahe upang ipagpatuloy o kanselahin ito.';

  @override
  String get youAreTogether => 'Magkasama na kayo';

  @override
  String get youChoseToWaitTheDriverMustConfirmTheVehicleIsSafeBefore =>
      'Pinili mong maghintay. Dapat kumpirmahin muna ng drayber na ligtas ang sasakyan bago ituloy ang nabigasyon.';

  @override
  String get yourAccount => 'Ang iyong account';

  @override
  String
  get yourAccountCannotPerformThisActionRefreshYourAccountOrContactSupport =>
      'Hindi maaaring gawin ng iyong account ang aksiyong ito. I-refresh ang account o makipag-ugnayan sa suporta.';

  @override
  String
  get yourAccountCanUploadApplicationDocumentsAndCheckApprovalGoingOnlineAndAccepting =>
      'Maaari kang mag-upload ng mga dokumento at tingnan ang pag-apruba. Kailangan ang pag-apruba ng administrador bago mag-online at tumanggap ng biyahe.';

  @override
  String get yourAccreditationIsVerified => 'Beripikado ang iyong akreditasyon';

  @override
  String get yourActivity => 'Iyong aktibidad';

  @override
  String get yourAdministratorRoleDoesNotIncludeThisArea =>
      'Hindi kasama ang bahaging ito sa iyong tungkulin bilang administrador.';

  @override
  String get yourAssignedTouristCanSeeYourLiveLocation =>
      'Nakikita ng nakatalagang turista ang iyong live na lokasyon';

  @override
  String get yourCompletedRidesWillAppearHere =>
      'Dito makikita ang iyong mga natapos na biyahe.';

  @override
  String get yourDocumentsAreUnderReview => 'Sinusuri ang iyong mga dokumento.';

  @override
  String get yourDriver => 'Iyong drayber';

  @override
  String get youReOffline => 'Naka-offline ka';

  @override
  String get youReReadyToRide => 'Handa ka nang bumiyahe';

  @override
  String yourFeedbackHelpsKeepAppTrusted(String brandName) {
    return 'Nakakatulong ang iyong feedback upang manatiling mapagkakatiwalaan ang $brandName.';
  }

  @override
  String
  get yourFixedFareRouteAndPaymentRecordStayUnchangedThePreviousDriverIs =>
      'Mananatili ang nakapirming pamasahe, ruta at tala ng pagbabayad. Aalisin ang dating drayber at magsisimula ang panibagong 10 minutong paghahanap.';

  @override
  String get yourGuideYourRideInBustos => 'Gabay at Sakay Mo sa Bustos';

  @override
  String get yourJourneyYourWay => 'Ang Biyahe Mo, sa Paraan Mo';

  @override
  String get yourLocalJourneyStartsHere =>
      'Ang iyong lokal na paglalakbay ay nagsisimula dito';

  @override
  String get yourPreviousCodeWillStopWorkingShareTheNewCodeOnlyAfterBoarding =>
      'Hindi na gagana ang dating code. Ibigay lamang ang bagong code kapag nakasakay ka na. Maaari kang humiling ng bagong code kada limang minuto.';

  @override
  String get yourRidesAndReceipts => 'Iyong mga sakay at resibo';

  @override
  String
  get yourTourIsReservedDriverMatchingBegins30MinutesBeforePickupAndReminders =>
      'Nakareserba na ang tour mo. Magsisimula ang paghahanap ng drayber 30 minuto bago ang sunduan. Makikita ang mga paalala sa Mga Abiso.';

  @override
  String get yourTravel => 'Ang iyong paglalakbay';

  @override
  String youWillBeSentToPaymongoTestCheckoutPaymentIsConfirmedOnlyAfter(
    String brandName,
  ) {
    return 'Dadalhin ka sa test checkout ng PayMongo. Makukumpirma lamang ang bayad kapag dumating sa $brandName ang secure na webhook.';
  }

  @override
  String get useDeviceLanguage => 'Gamitin ang wika ng device';

  @override
  String get philippineTime => 'Oras sa Pilipinas';

  @override
  String philippineDateTime(String value, String timeZone) {
    return '$value ($timeZone)';
  }

  @override
  String minutesDuration(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String hoursDuration(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oras',
      one: '1 oras',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesDuration(int hours, int minutes) {
    return '$hours oras $minutes min';
  }

  @override
  String numberOfTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biyahe',
      one: '1 biyahe',
    );
    return '$_temp0';
  }

  @override
  String activeTripLocationTitle(String brandName) {
    return 'Aktibo ang lokasyon ng biyahe sa $brandName';
  }

  @override
  String notificationUpdateTitle(String brandName) {
    return 'Update mula sa $brandName';
  }

  @override
  String fieldMustBeBetween(String field, int minimum, int maximum) {
    return 'Dapat nasa pagitan ng $minimum at $maximum ang $field.';
  }

  @override
  String selectedDestinationCount(int count) {
    return '$count destinasyon';
  }

  @override
  String spotCount(int count) {
    return '$count lugar';
  }

  @override
  String buildYourDayWithStops(int count) {
    return 'Buuin ang iyong araw ($count hintuan)';
  }

  @override
  String cancellationWithReason(String result, String reason) {
    return '$result. Dahilan: $reason';
  }

  @override
  String cashConfirmation(String payment, String actor, String confirmation) {
    return 'Kinumpirma ng $actor ang $payment; $confirmation.';
  }

  @override
  String get bothPartiesConfirmed => 'kinumpirma ng parehong panig';

  @override
  String get awaitingOtherParty => 'hinihintay ang kabilang panig';

  @override
  String get exportPending => 'Nakabinbin';

  @override
  String get exportFulfilled => 'Handa na ang kopya';

  @override
  String get exportRejected => 'Tinanggihan ang kahilingan';

  @override
  String get administrator => 'Tagapangasiwa';

  @override
  String get payment => 'Pagbabayad';

  @override
  String get signInDidNotComplete => 'Hindi natapos ang pag-sign in.';

  @override
  String get authResetConfigurationRequired =>
      'Hindi pa nakaayos ang pagbawi ng password para sa bersyong ito.';

  @override
  String get pickupRecoveryFailed =>
      'Hindi nakumpirma ang pagbawi ng kodigo sa sunduan. Subukang muli mula sa reserbasyon.';

  @override
  String get offlineReplayUnsafe =>
      'Hindi maaaring ulitin ang aksiyong ito nang offline.';

  @override
  String selectedStopsCount(int count) {
    return '$count napiling hintuan';
  }

  @override
  String cancellationGraceExpired(int minutes, int percent, String fee) {
    return 'Natapos na ang palugit na $minutes minuto. Ang nakasaad na bayad sa pagkansela na $percent% ay $fee. Ibigay ang dahilan bago kumpirmahin.';
  }

  @override
  String get arrivedAtPickup => 'Nakarating na ako sa sunduan';

  @override
  String get requestPickupReplacement =>
      'Hindi ako makakarating sa sunduan · humiling ng kapalit';

  @override
  String get confirmReachedStop => 'Oo, nakarating kami sa hintuang ito';

  @override
  String get reviewFinalCharge => 'Suriin at itakda ang huling singil';

  @override
  String trackingMovementSubtitle(String distance, String target, int seconds) {
    return '$distance $target · na-update ${seconds}s ang nakalipas';
  }

  @override
  String complianceServiceArea(String name, String radius) {
    return 'Sakop ng serbisyo: $name ($radius km)';
  }

  @override
  String get goOnline => 'Mag-online';

  @override
  String get call => 'Tumawag';

  @override
  String get sendMessage => 'Magpadala ng mensahe';

  @override
  String get share => 'Ibahagi';

  @override
  String get close => 'Isara';

  @override
  String get downloadReport => 'I-download ang ulat';

  @override
  String get markResolved => 'Markahang nalutas';

  @override
  String get changePhoto => 'Palitan ang larawan';

  @override
  String get savePlace => 'I-save ang lugar';

  @override
  String get suggestion => 'Mungkahi';

  @override
  String get luggage => 'Bagahe';

  @override
  String get assistance => 'Tulong';

  @override
  String get friendly => 'Magiliw';

  @override
  String get punctual => 'Nasa oras';

  @override
  String get terrible => 'Napakasama';

  @override
  String get bad => 'Hindi maganda';

  @override
  String get okay => 'Katamtaman';

  @override
  String get good => 'Maganda';

  @override
  String get excellent => 'Napakahusay!';

  @override
  String get province => 'Lalawigan';

  @override
  String get municipality => 'Munisipyo';

  @override
  String get resorts => 'Mga resort';

  @override
  String get events => 'Mga kaganapan';

  @override
  String get farmsNature => 'Mga bukid at kalikasan';

  @override
  String get foodCafes => 'Pagkain at mga kapihan';

  @override
  String get pickup => 'Sunduan';

  @override
  String get tricycle => 'Traysikel';

  @override
  String get oneYearMembership => '1 taon';

  @override
  String get lastThirtyDays => '30 araw';

  @override
  String get lastSevenDays => '7 araw';

  @override
  String get newTouristRating => ' 5.0 (Bago)';

  @override
  String get exampleOperatingHours => '8:00 AM – 5:00 PM';

  @override
  String get onePassenger => '1 pasahero';

  @override
  String get twoPassengers => '2 pasahero';

  @override
  String get threePassengers => '3 pasahero';

  @override
  String get removeSavedPlace => 'Alisin ang na-save na lugar';

  @override
  String get togglePhotoControls =>
      'Ipakita o itago ang mga kontrol ng larawan';

  @override
  String get paymentCheckoutCreated => 'Nagawa ang checkout';

  @override
  String get paymentProcessing => 'Pinoproseso ang bayad';

  @override
  String get paymentFailed => 'Nabigo ang pagbabayad';

  @override
  String get paymentAwaitingConfirmation =>
      'Naghihintay ng kumpirmasyon ng bayad';

  @override
  String get paymentRefundDue => 'May ibabalik na bayad';

  @override
  String get paymentRefundProcessing => 'Pinoproseso ang pagbabalik ng bayad';

  @override
  String get actorSystem => 'Sistema';

  @override
  String get statusBusy => 'Abala';

  @override
  String get privacyNoticeTitle => 'Paunawa sa pagkapribado';

  @override
  String get privacyWelcomeTitle => 'Mahalaga ang iyong pagkapribado';

  @override
  String privacyWelcomeBody(String brandName) {
    return 'Bago magpatuloy, suriin kung paano ginagamit ng $brandName ang iyong impormasyon at piliin ang iyong mga kagustuhan.';
  }

  @override
  String get privacyAccountTitle => 'Detalye ng account at biyahe';

  @override
  String get privacyAccountBody =>
      'Ginagamit ang iyong detalye para pamahalaan ang account, maghanap ng masasakyan at magtala ng biyahe.';

  @override
  String get privacyLocationTitle => 'Lokasyon kapag kailangan';

  @override
  String get privacyLocationBody =>
      'Ginagamit ang lokasyon para sa sunduan at nabigasyon. Hinihingi lang ang lokasyon sa background para sa serbisyo ng drayber.';

  @override
  String get privacyChoiceTitle => 'Ikaw ang may kontrol';

  @override
  String get privacyChoiceBody =>
      'Opsyonal ang mga ulat ng pag-crash. Maaari kang humiling ng iyong datos o mag-delete ng account sa iyong profile.';

  @override
  String get privacyFullNotice => 'Basahin ang buong paunawa';

  @override
  String get privacyDiagnosticsHelp =>
      'Opsyonal. Hindi maaapektuhan ang pag-sign in o mga reserbasyon kapag naka-off ito.';

  @override
  String get privacyRequiredHelp =>
      'Tanggapin ang paunawa para magpatuloy. Ikaw ang pipili kung magpapadala ng mga ulat.';

  @override
  String get privacyLoadingLabel =>
      'Sinusuri ang iyong mga kagustuhan sa pagkapribado';

  @override
  String privacyVersionLabel(String version) {
    return 'Bersiyon ng paunawa: $version';
  }

  @override
  String get tickTheAgreementToBook =>
      'Lagyan ng tsek ang kasunduan sa itaas para makapagpareserba.';

  @override
  String get driverDocumentsBlockOnline =>
      'May kulang, expired, o hindi pa beripikadong dokumento ng drayber. Tingnan ang iyong profile o makipag-ugnayan sa admin.';

  @override
  String get moveWithin150mOfPickup =>
      'Lumapit sa loob ng 150 metro mula sa sunduan at subukan muli.';

  @override
  String get gpsAccuracyTooLow =>
      'Mahina ang GPS signal. Lumipat sa bukas na lugar at subukan muli.';

  @override
  String kmFromTown(String km) {
    return '$km km mula sa bayan';
  }

  @override
  String get driverInServiceArea => 'Nasa loob ng serbisyo sa Bustos';

  @override
  String driverOutsideServiceArea(String km) {
    return '$km km mula sa Bustos';
  }

  @override
  String get noDriversOnlineRightNow => 'Walang drayber na online ngayon';

  @override
  String get noDriversOnlineBody =>
      'Maaari mo pa ring ipadala ang kahilingan, pero baka mag-expire ito bago may tumanggap. Kung iiskedyul mo sa ibang oras, may panahon ang mga drayber na makita ito.';

  @override
  String get scheduleForLater => 'Iiskedyul sa ibang oras';

  @override
  String get groupOfFourOrMore => 'Apat o higit pa kayo?';

  @override
  String get groupOfFourOrMoreBody =>
      'Hanggang 3 pasahero ang kasya sa isang traysikel. Magpareserba para sa 3, tapos hilingin sa isa pang kasama na magpareserba ng pangalawang traysikel sa sarili niyang phone para sa parehong tour.';

  @override
  String get locationExplainerTitle => 'Ipakita kung nasaan ka sa mapa';

  @override
  String get locationReasonMap =>
      'Makita kung gaano kalayo sa iyo ang bawat lugar.';

  @override
  String get locationReasonPickup =>
      'Gamitin ang kinaroroonan mo bilang sunduan para madali kang mahanap ng drayber.';

  @override
  String get locationReasonPrivacy =>
      'Ginagamit lang habang bukas ang app. Sunduan mo lang ang nakikita ng drayber, hindi ang live na lokasyon mo.';

  @override
  String get allowLocation => 'Payagan ang lokasyon';

  @override
  String get notNow => 'Mamaya na lang';

  @override
  String get inYourTrip => 'Nasa biyahe mo na';

  @override
  String get openBookingDetails => 'Buksan ang detalye ng reserbasyon';

  @override
  String get adminEscalatedOn => 'Ipinasa sa admin';
}
