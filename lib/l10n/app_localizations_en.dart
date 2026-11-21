// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get serverConnectionRequired =>
      'This action needs a connection to the server. Check your internet and sign in again.';

  @override
  String adminGcashDisputesOpen(int count) {
    return '$count disputed GCash fares';
  }

  @override
  String get outstandingFareBlocked =>
      'You have an unpaid fare from an earlier trip. Pay your driver, or ask support, before booking again.';

  @override
  String get outstandingFareTitle => 'Unpaid fare';

  @override
  String get outstandingFareAction => 'Open unpaid trip';

  @override
  String get gcashReferenceUsed =>
      'This GCash reference number was already used for another trip.';

  @override
  String get gcashProofRequired =>
      'Your driver reported the payment as not received. Send your receipt and reference number instead.';

  @override
  String get onlinePaymentUnavailable =>
      'Online card payment is no longer available. Choose cash or GCash.';

  @override
  String get gcashQrTitle => 'Driver\'s GCash QR';

  @override
  String get gcashSaveQr => 'Share or save QR';

  @override
  String get gcashQrHint =>
      'In GCash, tap Scan QR, then Upload QR, and choose this image. You can also scan the QR on the tricycle.';

  @override
  String get gcashQrMissing =>
      'This driver hasn\'t uploaded a QR code. Use the number below.';

  @override
  String get gcashUploadQr => 'Upload GCash QR';

  @override
  String get gcashReplaceQr => 'Replace QR';

  @override
  String get gcashQrSaved => 'QR code saved';

  @override
  String get gcashQrDescription =>
      'Tourists see your QR only when paying you for a completed trip.';

  @override
  String get gcashProofTitle => 'Send payment proof';

  @override
  String get gcashProofBody =>
      'Your driver hasn\'t received the payment yet. Attach your GCash receipt screenshot and the reference number.';

  @override
  String get gcashChooseReceipt => 'Choose receipt screenshot';

  @override
  String get gcashReceiptChosen => 'Receipt selected';

  @override
  String get gcashReferenceRequired => 'GCash reference number';

  @override
  String get gcashSubmitProof => 'Send proof';

  @override
  String get gcashProofSent => 'Proof sent to your driver';

  @override
  String get gcashViewReceipt => 'View receipt';

  @override
  String get gcashAskAdmin => 'Ask admin to decide';

  @override
  String get gcashAskAdminBody =>
      'Use this only if you can\'t settle it together. An admin will check the receipt and decide.';

  @override
  String get gcashAdminNote => 'Note for the admin (optional)';

  @override
  String get gcashSentToAdmin => 'Sent to admin review';

  @override
  String get gcashEscalatedNotice =>
      'An admin is reviewing this payment. You can still settle it together.';

  @override
  String get gcashRulingPaid => 'Admin decision: paid';

  @override
  String get gcashRulingNotPaid => 'Admin decision: not paid';

  @override
  String get gcashRulingWaived => 'Admin decision: fare waived';

  @override
  String get gcashReferenceLabel => 'GCash reference';

  @override
  String get adminGcashDisputes => 'GCash disputes';

  @override
  String get adminGcashDisputesEmpty => 'No open GCash disputes.';

  @override
  String get adminDisputeEscalated => 'Needs a decision';

  @override
  String get adminDisputeWaiting => 'Waiting for tourist and driver';

  @override
  String get adminDisputeUnsettled => 'Ruled not paid · unsettled';

  @override
  String get adminRulePaid => 'Rule paid';

  @override
  String get adminRuleNotPaid => 'Rule not paid';

  @override
  String get adminWaiveFare => 'Waive fare';

  @override
  String get adminRulingReason => 'Reason for your decision';

  @override
  String get adminNoReceipt => 'No receipt submitted yet.';

  @override
  String get adminDriverNote => 'Driver\'s note';

  @override
  String get adminEscalationNote => 'Escalation note';

  @override
  String get adminDecisionSaved => 'Decision saved';

  @override
  String get gcashSendToDriver => 'GCash (send to driver)';

  @override
  String get gcashAfterTrip =>
      'You\'ll send the fare to your driver\'s GCash after the trip.';

  @override
  String get gcashCompleteTrip => 'Complete trip';

  @override
  String get gcashDetails => 'GCash payment details';

  @override
  String get gcashNumber => 'GCash number';

  @override
  String get gcashConfirmNumber => 'Re-enter GCash number';

  @override
  String get gcashAccountName => 'Registered GCash account name';

  @override
  String get gcashActive => 'Accept GCash payments';

  @override
  String get gcashInactive => 'GCash payments disabled';

  @override
  String get gcashNotConfigured => 'This driver has not added GCash details.';

  @override
  String get gcashVisibility =>
      'Tourists will see this number and name when paying you by GCash.';

  @override
  String get gcashInvalidNumber =>
      'Enter a mobile number in 09XXXXXXXXX or +639XXXXXXXXX format.';

  @override
  String get gcashNumberMismatch => 'The GCash numbers must match.';

  @override
  String get gcashInvalidName =>
      'Enter the account name using 2 to 120 characters.';

  @override
  String get gcashCheckName =>
      'Before sending, check that the name shown in GCash matches this account name.';

  @override
  String get gcashOpen => 'Open GCash';

  @override
  String get gcashLaunchFailed =>
      'GCash isn\'t installed or couldn\'t be opened. You can still copy the number and amount.';

  @override
  String get gcashCopyNumber => 'Copy number';

  @override
  String get gcashCopyAmount => 'Copy amount';

  @override
  String get gcashNumberCopied => 'Number copied';

  @override
  String get gcashAmountCopied => 'Amount copied';

  @override
  String get gcashSent => 'I\'ve sent the payment';

  @override
  String get gcashReference => 'GCash reference number (optional)';

  @override
  String get gcashInvalidReference =>
      'Use 8 to 20 letters or digits for the reference number.';

  @override
  String get gcashPayCash => 'Pay with cash instead';

  @override
  String get gcashNotSetUp =>
      'Your driver hasn\'t set up GCash. Please pay with cash.';

  @override
  String get gcashAwaitingDriver => 'Awaiting driver confirmation';

  @override
  String get gcashAwaitingYour => 'Awaiting your confirmation';

  @override
  String get gcashDisputed => 'GCash payment disputed';

  @override
  String get gcashDisputeMessage =>
      'Your driver hasn\'t received the payment yet. Check your GCash receipt and reference number, or pay in cash.';

  @override
  String get gcashSlide => 'Slide to confirm payment received';

  @override
  String get gcashDriverConfirm => 'Confirm payment received';

  @override
  String get gcashNotReceived => 'Not received yet';

  @override
  String get gcashDisputeNote => 'Short note (optional)';

  @override
  String get gcashPaidByDriver => 'Payment confirmed by driver';

  @override
  String get gcashActionFailed =>
      'Could not complete this GCash action. Refresh the booking and try again.';

  @override
  String get gcashSettingsSaved => 'GCash details saved';

  @override
  String get gcashCashWarning =>
      'If you already sent money, check your GCash receipt with the driver before paying in cash.';

  @override
  String get gcashFareToPay => 'Fare to pay';

  @override
  String get gcashCheckWallet =>
      'Check that the fare arrived in your GCash before confirming.';

  @override
  String get gcashAmountReceived => 'GCash fare received';

  @override
  String get gcashConfirmedFares => 'Confirmed fares';

  @override
  String get gcashConfirmedFaresOverTime => 'Confirmed fares over time';

  @override
  String get loadedBookingTotals =>
      'These figures cover only bookings loaded in the app.';

  @override
  String get gcashEarningsExplanation =>
      'Includes confirmed direct GCash fares. Amounts under review are excluded.';

  @override
  String get abc1234 => 'ABC 1234';

  @override
  String get abc1234AccreditedDriver => 'ABC 1234 • Accredited driver';

  @override
  String get about => 'About';

  @override
  String get accept => 'ACCEPT';

  @override
  String get acceptAndContinue => 'Accept and continue';

  @override
  String get acceptAssistanceRequests => 'Accept assistance requests';

  @override
  String get accepted => 'accepted';

  @override
  String get acceptTheCurrentPrivacyNoticeBeforeSubmitting =>
      'Accept the current privacy notice before submitting.';

  @override
  String get accessibilityOrAssistanceNeeds =>
      'Accessibility or assistance needs';

  @override
  String get account => 'Account';

  @override
  String get accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain =>
      'Account access could not be completed. Check your details and try again.';

  @override
  String get accountCreatedConfirmYourEmailThenSignIn =>
      'Account created. Confirm your email, then sign in.';

  @override
  String get accreditationVerified => 'Accreditation verified';

  @override
  String get aConfiguredServerAndAdministratorAccountAreRequired =>
      'A configured server and administrator account are required.';

  @override
  String get activate => 'Activate';

  @override
  String get activateTourist => 'Activate tourist';

  @override
  String activateValue(String value) {
    return 'Activate $value';
  }

  @override
  String get active => 'Active';

  @override
  String get activeTrip => 'Active trip';

  @override
  String get activeTripRoute => 'Active trip route';

  @override
  String get actNow => 'Act now';

  @override
  String get addAStatementToThisCase => 'Add a statement to this case';

  @override
  String get addedToItinerary => 'Added to itinerary!';

  @override
  String get addedToYourItinerary => 'Added to your itinerary!';

  @override
  String get address => 'Address';

  @override
  String get addressDetails => 'Address details';

  @override
  String get addressMatchesPin => 'Address matches pin';

  @override
  String get addToTrip => '+ Add to Trip';

  @override
  String get addToTripLabel => 'Add to Trip';

  @override
  String get addTouristSpot => 'Add tourist spot';

  @override
  String get addYourStatement => 'Add your statement';

  @override
  String get aDestinationIsNoLongerAvailableUpdateYourItinerary =>
      'A destination is no longer available. Update your itinerary.';

  @override
  String get adjustPin => 'Adjust pin';

  @override
  String get adminEmail => 'Admin email';

  @override
  String get administratorUpdatedFixedFares =>
      'Administrator updated fixed fares.';

  @override
  String get adminPasswordIsRequired => 'Admin password is required';

  @override
  String get adminPortal => 'Admin portal';

  @override
  String get adminReviewPaymentOnHold => 'Admin review · payment on hold';

  @override
  String
  get affectedTouristsAndAssignedDriversWillBeNotifiedExistingBookingsKeepAnAudit =>
      'Affected tourists and assigned drivers will be notified. Existing bookings keep an audit record.';

  @override
  String get agreeAndContinue => 'Agree and continue';

  @override
  String get agreedFare => 'Agreed fare';

  @override
  String get agreedFixedFare => 'Agreed fixed fare';

  @override
  String
  agreedMaximumStopsConfirmedByTheTouristTheSuggestedProratedAmountIsAValue(
    String value,
    String secondValue,
    String thirdValue,
  ) {
    return 'Agreed maximum: $value. $secondValue/$thirdValue stops confirmed by the tourist. The suggested prorated amount is a starting point only. Review both statements, safety concerns and service delivered. No penalties or extras.';
  }

  @override
  String get agreedPolicy => 'Agreed policy';

  @override
  String agreedValue(String value) {
    return 'Agreed\n₱$value';
  }

  @override
  String get all => 'All';

  @override
  String get allowLocationAccessInAndroidSettings =>
      'Allow location access in Android settings.';

  @override
  String get allowMatchingForTouristsWithMobilityOrBoardingNeeds =>
      'Allow matching for tourists with mobility or boarding needs.';

  @override
  String get allowOptionalCrashDiagnostics =>
      'Allow optional crash diagnostics';

  @override
  String get allStopsAreConfirmedOpenTripControlsToFinish =>
      'All stops are confirmed. Open Trip controls to finish.';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get aNearbyTouristIsLookingForADriver =>
      'A nearby tourist is looking for a driver.';

  @override
  String get announcementSentSuccessfully => 'Announcement sent successfully';

  @override
  String get anotherAccountIsAlreadySignedInSignOutBeforeRegisteringADriver =>
      'Another account is already signed in. Sign out before registering a driver.';

  @override
  String get aPackageStopIsUnavailablePleaseChooseAnotherRoute =>
      'A package stop is unavailable. Please choose another route.';

  @override
  String appDriverIsOnline(String brandName) {
    return '$brandName driver is online';
  }

  @override
  String get applicationPending => 'Application pending';

  @override
  String get applicationRejected => 'Application rejected.';

  @override
  String get applicationSubmittedForAdministratorReview =>
      'Application submitted for administrator review.';

  @override
  String appManagementSystem(String brandName) {
    return '$brandName Management System';
  }

  @override
  String appName(String brandName) {
    return '$brandName';
  }

  @override
  String appReportValue(String value, String brandName) {
    return '$brandName $value report';
  }

  @override
  String get approveAndEnableMatching => 'Approve and enable matching';

  @override
  String get approved => 'Approved';

  @override
  String get approvedServiceArea => 'Approved service area';

  @override
  String get approveRouteChange => 'Approve route change';

  @override
  String get apr => 'Apr';

  @override
  String get aPrePickupReviewCannotIncreaseTheSnapshottedCancellationCharge =>
      'A pre-pickup review cannot increase the snapshotted cancellation charge.';

  @override
  String
  get aPreviousBookingRequestIsAwaitingConfirmationReconnectAndOpenTripsBeforeChanging =>
      'A previous booking request is awaiting confirmation. Reconnect and open Trips before changing the request.';

  @override
  String get areaName => 'Area name';

  @override
  String get areaUnverified => 'Area unverified';

  @override
  String areCurrentlyOnATripValue(String value) {
    return '$value are currently on a trip';
  }

  @override
  String get areYouInAnEmergency => 'Are you in an emergency?';

  @override
  String get areYouSureYouWantToLogOut => 'Are you sure you want to log out?';

  @override
  String areYouSureYouWantToLogOutOfApp(String brandName) {
    return 'Are you sure you want to log out of $brandName?';
  }

  @override
  String arrivalReportedValue(String value) {
    return 'Arrival reported: $value.';
  }

  @override
  String get askTheTouristForTheCorrectPickupCodeOnceTheyAreOnBoard =>
      'Ask the tourist for the correct pickup code once they are on board.';

  @override
  String get askTheTouristForTheirCodeAfterTheyAreSafelyOnBoard =>
      'Ask the tourist for their code after they are safely on board.';

  @override
  String get assignedDriver => 'Assigned driver';

  @override
  String get attachBothRequiredDriverDocuments =>
      'Attach both required driver documents.';

  @override
  String attachedValue(String value) {
    return '$value attached';
  }

  @override
  String get attraction => 'Attraction';

  @override
  String attractionAndFareInformationIsSynchronizedWithApp(String brandName) {
    return 'Attraction and fare information is synchronized with $brandName.';
  }

  @override
  String get audience => 'Audience';

  @override
  String audienceValue(String value) {
    return 'Audience: $value';
  }

  @override
  String get auditedRouteChangesRequireTheConfiguredServer =>
      'Audited route changes require the configured server.';

  @override
  String get aug => 'Aug';

  @override
  String get availability => 'Availability';

  @override
  String avatarCleanupPendingForObjectValue(String value) {
    return 'Avatar cleanup pending for object $value';
  }

  @override
  String get avatarObjectVersionIsInvalid =>
      'Avatar object version is invalid.';

  @override
  String get avatarOwnerIsInvalid => 'Avatar owner is invalid.';

  @override
  String get awaitingBothCashConfirmations =>
      'Awaiting both cash confirmations';

  @override
  String awaitingPaymentValue(String value) {
    return 'Awaiting payment: ₱$value';
  }

  @override
  String get back => 'Back';

  @override
  String get backToExplore => 'Back to explore';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get backToUserLogin => 'Back to User Login';

  @override
  String get barangay => 'Barangay';

  @override
  String get blocked => 'Blocked';

  @override
  String get blockedCheckoutExpiry => 'Blocked checkout expiry';

  @override
  String get bongaMayor => 'Bonga mayor';

  @override
  String get bongaMenor => 'Bonga menor';

  @override
  String get bookATourToGetStarted => 'Book a tour to get started!';

  @override
  String get bookATricycle => 'Book a Tricycle';

  @override
  String bookForValue(String value) {
    return 'Book for ₱$value';
  }

  @override
  String get booking => 'Booking';

  @override
  String get bookingAndSystemUpdates => 'Booking and system updates';

  @override
  String get bookingDetailsCancel => 'Booking details / cancel';

  @override
  String get bookingDriverPaymentAndSafetyUpdates =>
      'Booking, driver, payment, and safety updates';

  @override
  String get bookingHistory => 'Booking history';

  @override
  String get bookingNotFoundForThisAccount =>
      'Booking not found for this account.';

  @override
  String get bookings => 'Bookings';

  @override
  String get bookingSessionChanged => 'Booking session changed.';

  @override
  String get bookingsPaymentReviews => 'Bookings & payment reviews';

  @override
  String get bookingsToday => 'Bookings today';

  @override
  String bookingValue(String value) {
    return 'Booking $value';
  }

  @override
  String get bookNow => 'Book now';

  @override
  String get bookThisTour => 'Book this tour';

  @override
  String get bothDriverDocumentsAreRequired =>
      'Both driver documents are required.';

  @override
  String get bothDriverDocumentsMustBeValidImagesUnder5Mb =>
      'Both driver documents must be valid images under 5 MB.';

  @override
  String get brandMark => 'T';

  @override
  String get broadcastAMessage => 'Broadcast a Message';

  @override
  String get bugReport => 'Bug report';

  @override
  String get buildADayYouLlRemember => 'Build a day you\'ll remember';

  @override
  String get buildYourDay => 'Build your day';

  @override
  String get buildYourItineraryAndEnjoyAPersonalizedTourExperience =>
      'Build your itinerary and enjoy a personalized tour experience.';

  @override
  String get buildYourOwnDay => 'Build your own day';

  @override
  String bulletItem(String value) {
    return '• $value';
  }

  @override
  String get bustosBulacan => 'Bustos, Bulacan';

  @override
  String get bustosTourMap => 'Bustos tour map';

  @override
  String get bustosTownCentre => 'Bustos town centre';

  @override
  String get calculatingLocalRoadRoute => 'Calculating local-road route...';

  @override
  String get callEmergencyServices => 'Call emergency services?';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelBooking => 'Cancel booking?';

  @override
  String cancelBookingFeeValue(String value) {
    return 'Cancel booking | $value% fee';
  }

  @override
  String get cancelBookingNoCharge => 'Cancel booking | no charge';

  @override
  String get cancelFree => 'Cancel free';

  @override
  String get cancelFreeOfCharge => 'Cancel free of charge';

  @override
  String get cancellationAndPaymentPolicy => 'Cancellation and payment policy';

  @override
  String get cancelled => 'cancelled';

  @override
  String get cancelledAfterTheGracePeriodPublishedCancellationFeeApplied =>
      'Cancelled after the grace period; published cancellation fee applied';

  @override
  String get cancelledWithoutCharge => 'Cancelled without charge';

  @override
  String get cancelThisBooking => 'Cancel this booking?';

  @override
  String get capacity => 'Capacity';

  @override
  String caseStatementValue(String value) {
    return 'Case statement: $value';
  }

  @override
  String get cash => 'Cash';

  @override
  String get cashConfirmedByBoth => 'Cash confirmed by both';

  @override
  String get cashConfirmedByBothParties => 'Cash confirmed by both parties';

  @override
  String
  get cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts =>
      'Cash confirmed by both parties, after returns. Filtered by trip end date. Amounts under review are excluded.';

  @override
  String get cashNotConfirmed => 'Cash not confirmed';

  @override
  String get cashPayment => 'Cash payment';

  @override
  String get cashReturn => 'Cash return';

  @override
  String get cashReturnConfirmed => 'Cash return confirmed';

  @override
  String get cashReturnOutstanding => 'Cash return outstanding';

  @override
  String get cashToReturn => 'Cash to return';

  @override
  String get category => 'Category';

  @override
  String get centerLatitude => 'Center latitude';

  @override
  String get centerLongitude => 'Center longitude';

  @override
  String
  get changingServiceCapacityRequiresAdministratorApprovalBeforeYouCanGoOnlineAgain =>
      'Changing service capacity requires administrator approval before you can go online again.';

  @override
  String get checkApproval => 'Check approval';

  @override
  String get checkingGpsAndPermission => 'Checking GPS and permission.';

  @override
  String get checkLocally => 'Check locally';

  @override
  String get checkoutCouldNotBeCreated => 'Checkout could not be created.';

  @override
  String checkOutInBustosBulacanValue(String value) {
    return 'Check out $value in Bustos, Bulacan! 🏝️';
  }

  @override
  String get checkRoadRestrictions => 'Check road restrictions';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get chooseABarangayAndEnterTheExactAddressBelow =>
      'Choose a barangay and enter the exact address below';

  @override
  String get chooseAnExactPickupPointBeforeBooking =>
      'Choose an exact pickup point before booking';

  @override
  String get chooseAPickupPointOnTheMapOrEnableLocationFirst =>
      'Choose a pickup point on the map or enable location first.';

  @override
  String get chooseBothDocumentsAndExpiryDates =>
      'Choose both documents and expiry dates.';

  @override
  String get chooseFranchiseExpiry => 'Choose franchise expiry';

  @override
  String chooseHowYouWantToUseApp(String brandName) {
    return 'Choose how you want to use $brandName';
  }

  @override
  String get chooseJpegDocumentImages => 'Choose JPEG document images.';

  @override
  String get chooseLicenseExpiry => 'Choose license expiry';

  @override
  String get chooseLicenseImage => 'Choose license image';

  @override
  String get choosePickupDate => 'Choose pickup date';

  @override
  String get choosePickupTime => 'Choose pickup time';

  @override
  String get choosePlacesSeeYourFareBookARide =>
      'Choose places, see your fare, book a ride.';

  @override
  String get chooseThePlacesYouWantToVisitInOneTrip =>
      'Choose the places you want to visit in one trip.';

  @override
  String get chooseVehicleRegistrationImage =>
      'Choose vehicle registration image';

  @override
  String get chooseWhoShouldReceiveThisAnnouncementThenReviewBeforeSending =>
      'Choose who should receive this announcement, then review before sending.';

  @override
  String get chooseYourWorkspaceThenSignInToContinue =>
      'Choose your workspace, then sign in to continue.';

  @override
  String get church => 'Church';

  @override
  String get cleanVehicle => 'Clean vehicle';

  @override
  String get clearAll => 'Clear all';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get closeAndNotify => 'Close and notify';

  @override
  String get closeAttractionDetails => 'Close attraction details';

  @override
  String get closed => 'Closed';

  @override
  String get closeTemporarily => 'Close temporarily';

  @override
  String get closureReason => 'Closure reason';

  @override
  String get codeReissueCouldNotBeConfirmed =>
      'Code reissue could not be confirmed.';

  @override
  String compactCurrency(String value) {
    return '₱${value}k';
  }

  @override
  String get completeAllDocumentAndServiceAreaFields =>
      'Complete all document and service-area fields.';

  @override
  String get completed => 'completed';

  @override
  String get completedAndActiveBookings => 'Completed and active bookings';

  @override
  String get completedTrips => 'Completed trips';

  @override
  String get completeRefund => 'Complete refund';

  @override
  String get completeTestModeRefund => 'Complete test-mode refund?';

  @override
  String get completeTestModeRefundLabel => 'Complete test-mode refund';

  @override
  String get completeTripCashStillUnconfirmed =>
      'Complete trip · cash still unconfirmed';

  @override
  String get complianceApproved => 'Compliance approved';

  @override
  String get complianceReviewRequired => 'Compliance review required';

  @override
  String get complianceReviewSaved => 'Compliance review saved.';

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmAmount => 'Confirm amount';

  @override
  String get confirmAndSend => 'Confirm and send';

  @override
  String get confirmCashExchanged => 'Confirm cash exchanged?';

  @override
  String get confirmCashPaid => 'Confirm cash paid';

  @override
  String get confirmCashReceived => 'Confirm cash received';

  @override
  String get confirmCashReturned => 'Confirm cash returned?';

  @override
  String get confirmCashReturnedLabel => 'Confirm cash returned';

  @override
  String get confirmCashReturnReceived => 'Confirm cash return received';

  @override
  String get confirmChange => 'Confirm change';

  @override
  String get confirmedCash => 'Confirmed cash';

  @override
  String get confirmedEntriesArePermanentAndCannotBeEditedOrDeleted =>
      'Confirmed entries are permanent and cannot be edited or deleted.';

  @override
  String
  get confirmedTransactionsOnlyOpenReviewsAndOutstandingRefundsAreExcluded =>
      'Confirmed transactions only. Open reviews and outstanding refunds are excluded.';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get confirmNoShow => 'Confirm no-show';

  @override
  String
  confirmOnlyAfterHasPhysicallyChangedHandsTheOtherPartyMustConfirmTooValue(
    String value,
  ) {
    return 'Confirm only after $value has physically changed hands. The other party must confirm too. Do not confirm a promised or partial payment.';
  }

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmRefund => 'Confirm refund';

  @override
  String confirmThatYouStayedAtTheVerifiedPickupPointUntilTheWaitingPeriodValue(
    String value,
    String secondValue,
  ) {
    return 'Confirm that you stayed at the verified pickup point until the waiting period ended and tried to contact the tourist. The published $value% no-show fee is $secondValue. This action is recorded and can be disputed.';
  }

  @override
  String get confirmThePickupPin => 'Confirm the pickup pin';

  @override
  String get confirmYourEmailThenSignInAsADriverToFinishUploadingYour =>
      'Confirm your email, then sign in as a driver to finish uploading your application.';

  @override
  String get connectionUnavailableCheckYourInternetConnectionAndTryAgain =>
      'Connection unavailable. Check your internet connection and try again.';

  @override
  String get connectToTheInternetAndRetry =>
      'Connect to the internet and retry.';

  @override
  String get contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown =>
      'Contact updates are unavailable. Only the national fallback is shown.';

  @override
  String get couldNotGetACurrentGpsPositionCheckYourSignalAndTryAgain =>
      'Could not get a current GPS position. Check your signal and try again.';

  @override
  String
  get couldNotGoOfflineLocationSharingRemainsActiveUntilTheServerConfirmsIt =>
      'Could not go offline. Location sharing remains active until the server confirms it.';

  @override
  String get couldNotGoOnlineYourAvailabilityWasNotChanged =>
      'Could not go online. Your availability was not changed.';

  @override
  String get couldNotLaunchPhoneDialer => 'Could not launch phone dialer';

  @override
  String couldNotLaunchValue(String value) {
    return 'Could not launch $value';
  }

  @override
  String get couldNotOpenCheckoutResumePaymentFromThisBooking =>
      'Could not open checkout. Resume payment from this booking.';

  @override
  String get couldNotOpenMessages => 'Could not open messages.';

  @override
  String get couldNotOpenNavigation => 'Could not open navigation.';

  @override
  String get couldNotOpenPhoneDialer => 'Could not open phone dialer.';

  @override
  String get couldNotOpenThePhoneDialerCall911Manually =>
      'Could not open the phone dialer. Call 911 manually.';

  @override
  String get couldNotOpenThePhoneDialerCallTheDisplayedNumberManually =>
      'Could not open the phone dialer. Call the displayed number manually.';

  @override
  String get couldNotOpenThisDocument => 'Could not open this document.';

  @override
  String get couldNotSaveNoBookingOrPaymentStateWasChanged =>
      'Could not save. No booking or payment state was changed.';

  @override
  String get couldNotSaveThisChangePleaseRetryThePreviousTripStateHasBeen =>
      'Could not save this change. Please retry; the previous trip state has been kept.';

  @override
  String get couldNotSynchronizeWithTheServerCheckYourConnectionAndRetry =>
      'Could not synchronize with the server. Check your connection and retry.';

  @override
  String get createANewPassword => 'Create a new password';

  @override
  String get createTouristAccount => 'Create tourist account';

  @override
  String
  get criticalConditionsAlsoAppearInOperationalAlertsInvestigateBeforeClearingAnAlert =>
      'Critical conditions also appear in operational alerts. Investigate before clearing an alert.';

  @override
  String get curatedExperience => 'CURATED EXPERIENCE';

  @override
  String get currentGpsLocation => 'Current GPS location';

  @override
  String get currentGpsPickup => 'Current GPS pickup';

  @override
  String get currentLocation => 'Current location';

  @override
  String get customTour => 'Custom tour';

  @override
  String get customTour112SelectedStops => 'Custom tour (1–12 selected stops)';

  @override
  String
  customTourNewBookingsUseTheseRatesExistingBookingsKeepTheirAgreedFareValue(
    String value,
    String secondValue,
  ) {
    return 'Custom tour: ₱$value\n$secondValue\n\nNew bookings use these rates. Existing bookings keep their agreed fare.';
  }

  @override
  String get dataExportRequests => 'Data export requests';

  @override
  String daysAgoValue(String value) {
    return '$value days ago';
  }

  @override
  String get dec => 'Dec';

  @override
  String get decisionAndReasoning => 'Decision and reasoning';

  @override
  String get decline => 'DECLINE';

  @override
  String get decliningMatchedOffersRequiresTheConfiguredServer =>
      'Declining matched offers requires the configured server.';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAccount => 'Delete account?';

  @override
  String deletedValue(String value) {
    return '$value deleted';
  }

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get deletingAccount => 'Deleting account…';

  @override
  String get deletionPending => 'Deletion pending';

  @override
  String
  get describeTheDisagreementCollectionAndRefundConfirmationsWillPauseUntilAnAdminReviews =>
      'Describe the disagreement. Collection and refund confirmations will pause until an admin reviews it.';

  @override
  String get description => 'Description';

  @override
  String get destination => 'Destination';

  @override
  String get destinations => 'destinations';

  @override
  String get destinationsYouLove => 'Destinations you love';

  @override
  String get directions => 'Directions';

  @override
  String get directionsRequireBetween2And25Coordinates =>
      'Directions require between 2 and 25 coordinates.';

  @override
  String get discover => 'Discover';

  @override
  String get discoverBustos => 'Discover Bustos';

  @override
  String get disputePaymentReportAProblem =>
      'Dispute payment / report a problem';

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
    return '$value documents are waiting for verification';
  }

  @override
  String get documentsDatesServiceAreaAndReliabilityMeetTheMatchingRules =>
      'Documents, dates, service area, and reliability meet the matching rules.';

  @override
  String get documentsPassword => 'Documents & Password';

  @override
  String get done => 'Done';

  @override
  String get donTHaveAnAccount => 'Don\'t have an account?';

  @override
  String get downloadExport => 'Download export';

  @override
  String get dragTheMapToPinYourExactLocation =>
      'Drag the map to pin your exact location';

  @override
  String get drive => 'Drive';

  @override
  String get driver => 'Driver';

  @override
  String get driverAcceptedTheFixedFareAndPickup =>
      'Driver accepted the fixed fare and pickup.';

  @override
  String get driverAccount => 'Driver account';

  @override
  String get driverApplication => 'Driver application';

  @override
  String get driverApprovedAndMatchingEnabled =>
      'Driver approved and matching enabled.';

  @override
  String get driverArrival => 'Driver arrival';

  @override
  String get driverArrivedAtTheVerifiedPickupAreaTheWaitingPeriodStarted =>
      'Driver arrived at the verified pickup area. The waiting period started.';

  @override
  String get driverBookings => 'Driver bookings';

  @override
  String get driverCancellationRateExceedsThe30MatchingLimit =>
      'Driver cancellation rate exceeds the 30% matching limit.';

  @override
  String get driverCancellations => 'Driver cancellations';

  @override
  String get driverCompliance => 'Driver compliance';

  @override
  String get driverComplianceRecordsWillAppearHere =>
      'Driver compliance records will appear here.';

  @override
  String get driverConcern => 'Driver concern';

  @override
  String get driverDocumentsMustBeJpegImages5MbMaximumEach =>
      'Driver documents must be JPEG images, 5 MB maximum each.';

  @override
  String get driverHasArrived => 'Driver has arrived';

  @override
  String get driverIsMoving => 'Driver is moving';

  @override
  String get driverIsStopped => 'Driver is stopped';

  @override
  String get driverLicense => 'Driver license';

  @override
  String get driverLicenseDocumentIsMissing =>
      'Driver license document is missing.';

  @override
  String get driverLicenseExpiry => 'Driver license expiry';

  @override
  String get driverMatchingBegins30MinutesBeforePickup =>
      'Driver matching begins 30 minutes before pickup.';

  @override
  String get driverNotFound => 'Driver not found';

  @override
  String get driverPerformance => 'Driver performance';

  @override
  String get driverRegistration => 'Driver registration';

  @override
  String get driverReplacementRequested => 'Driver replacement requested';

  @override
  String get driverReplacementRequiresTheConfiguredServer =>
      'Driver replacement requires the configured server.';

  @override
  String get driverReportedArrivalAwaitingTourist =>
      'Driver reported arrival · awaiting tourist';

  @override
  String get driverReviewSubmitted => 'Driver review submitted.';

  @override
  String get drivers => 'Drivers';

  @override
  String driversActiveValue(String value) {
    return 'Active drivers: $value';
  }

  @override
  String get driverSearchRetriedForAnother10Minutes =>
      'Driver search retried for another 10 minutes.';

  @override
  String driversHaveToAcceptThisSearchRequestYouCanLeaveThisScreenAndValue(
    String value,
  ) {
    return 'Drivers have $value to accept this search request. You can leave this screen and return through Trips. No fare is charged while waiting.';
  }

  @override
  String get driverSuspendedFor30Days => 'Driver suspended for 30 days.';

  @override
  String get driverTools => 'Driver tools';

  @override
  String get driverTrackingPreview => 'Driver tracking preview';

  @override
  String driverValue(String value) {
    return 'Driver: $value';
  }

  @override
  String get driverVerifications => 'Driver verifications';

  @override
  String get eachDriverDocumentMustBe5MbOrSmaller =>
      'Each driver document must be 5 MB or smaller.';

  @override
  String get earlier => 'Earlier';

  @override
  String get earnings => 'Earnings';

  @override
  String get earningsInsights => 'Earnings insights';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editTouristSpot => 'Edit tourist spot';

  @override
  String get eG123RizalStNearTheBakery => 'e.g. 123 Rizal St. near the bakery';

  @override
  String get eGMinasaFestivalGrounds => 'e.g. Minasa Festival Grounds';

  @override
  String get eGSystemMaintenance => 'e.g. System Maintenance';

  @override
  String get email => 'Email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressIsRequired => 'Email address is required';

  @override
  String emailAddressMustNotExceedCharactersValue(String value) {
    return 'Email address must not exceed $value characters';
  }

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get emailReadOnly => 'Email (Read-only)';

  @override
  String get emergency => 'Emergency';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get emergencyContacts => 'Emergency contacts';

  @override
  String get emergencyContactsSettings => 'Emergency contacts settings';

  @override
  String get emergencyHelp => 'Emergency help';

  @override
  String get emergencySafety => 'Emergency & Safety';

  @override
  String get endSafelyReviewPayment => 'End safely · review payment';

  @override
  String get endTheTourSafelyFirstToOpenASettlementReview =>
      'End the tour safely first to open a settlement review.';

  @override
  String get endTourEarly => 'End tour early?';

  @override
  String get endTourEarlyReportAProblem => 'End tour early / report a problem';

  @override
  String get english => 'English';

  @override
  String get englishName => 'English name';

  @override
  String get enterAClearClosureReason => 'Enter a clear closure reason.';

  @override
  String get enterAClearReasonForTheAuditHistory =>
      'Enter a clear reason for the audit history';

  @override
  String get enterAClearReasonForThisChange =>
      'Enter a clear reason for this change.';

  @override
  String get enterAddress => 'Enter address...';

  @override
  String get enterAnAdminEmail => 'Enter an admin email';

  @override
  String get enterAPhMobileNumberOrInternationalNumberWithCountryCode =>
      'Enter a PH mobile number or international number with +country code';

  @override
  String get enterAPriceBetween001And100000 =>
      'Enter a price between ₱0.01 and ₱100,000.';

  @override
  String get enterAReasonOfAtLeastFiveCharacters =>
      'Enter a reason of at least five characters.';

  @override
  String get enterAValidAmountWithAtMostTwoDecimals =>
      'Enter a valid amount with at most two decimals.';

  @override
  String get enterAValidEmail => 'Enter a valid email';

  @override
  String get enterAValidPhoneNumber => 'Enter a valid phone number';

  @override
  String get enterAValidPrice => 'Enter a valid price';

  @override
  String get enterDescription => 'Enter description...';

  @override
  String get enterDriverApp => 'Enter driver app';

  @override
  String get enterHistory => 'Enter history...';

  @override
  String get enterPesosWithAtMostTwoDecimalPlaces =>
      'Enter pesos with at most two decimal places.';

  @override
  String get enterThePickupAddressBelow => 'Enter the pickup address below.';

  @override
  String
  get enterTheReasonForApprovingOrRestoringServiceAtLeastFiveCharacters =>
      'Enter the reason for approving or restoring service (at least five characters).';

  @override
  String get enterTouristApp => 'Enter tourist app';

  @override
  String get enterValidFixedFaresForEveryRoute =>
      'Enter valid fixed fares for every route.';

  @override
  String get enterYourAnnouncementDetailsHere =>
      'Enter your announcement details here...';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourEmailAndWeWillSendYouALinkToResetYour =>
      'Enter your email and we will send you a link to reset your password.';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get entranceFee => 'Entrance fee';

  @override
  String get entranceFeesMayApply => '+ entrance fees may apply';

  @override
  String get eta => 'ETA';

  @override
  String get exampleEmailCom => 'example@email.com';

  @override
  String get exampleSeniorPassengerNeedsExtraBoardingTime =>
      'Example: senior passenger needs extra boarding time';

  @override
  String get exampleTwoBackpacksAndOneFoldingStroller =>
      'Example: two backpacks and one folding stroller';

  @override
  String get exampleUpdatedOperatingCostApprovedByAdmin =>
      'Example: Updated operating cost approved by admin';

  @override
  String get expectedReopening => 'Expected reopening';

  @override
  String expectedReopeningValue(String value) {
    return 'Expected reopening: $value';
  }

  @override
  String expiryIsNotVerifiedValue(String value) {
    return '$value expiry is not verified.';
  }

  @override
  String get expiryVerification => 'Expiry verification';

  @override
  String get explainAnythingTheDriverMustCorrect =>
      'Explain anything the driver must correct';

  @override
  String get explainTheDecisionAtLeast10Characters =>
      'Explain the decision (at least 10 characters).';

  @override
  String get explainTheDecisionClearly => 'Explain the decision clearly';

  @override
  String get explainThePolicyInAtLeast20Characters =>
      'Explain the policy in at least 20 characters.';

  @override
  String get explore => 'Explore';

  @override
  String get exploreBustos => 'Explore Bustos';

  @override
  String get exploreSpotsBuildItinerariesAndBookTricyclesEasily =>
      'Explore spots, build itineraries, and book tricycles easily.';

  @override
  String get exploreTheHeritageNatureAndBeautyOfBustosBulacanWithEase =>
      'Explore the heritage, nature, and beauty of Bustos, Bulacan with ease.';

  @override
  String get exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited =>
      'Exports are delivered only to the requesting account. Fulfilment is audited.';

  @override
  String get f123456 => 'F-123456';

  @override
  String get failedPayments => 'Failed payments';

  @override
  String get feb => 'Feb';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackMarkedResolved => 'Feedback marked resolved';

  @override
  String get feedbackSubmittedThankYou => 'Feedback submitted! Thank you 🙏';

  @override
  String get filipino => 'Filipino';

  @override
  String get filipinoName => 'Filipino name';

  @override
  String get finalCharge => 'Final charge (₱)';

  @override
  String get finalChargeLabel => 'Final charge';

  @override
  String finalChargeValue(String value, String secondValue) {
    return 'Final charge: ₱$value · $secondValue';
  }

  @override
  String get financeAdministratorAccessIsRequired =>
      'Finance administrator access is required.';

  @override
  String get financialRecord => 'Financial record';

  @override
  String get findADriver => 'Find a driver';

  @override
  String get findAnotherDriver => 'Find another driver';

  @override
  String get findAnotherDriverLabel => 'Find another driver?';

  @override
  String get findingYourLocation => 'Finding your location…';

  @override
  String get findMyDriver => 'Find my driver';

  @override
  String get finishOrCancelTheActiveTripBeforeGoingOffline =>
      'Finish or cancel the active trip before going offline.';

  @override
  String get finishYourCurrentTripBeforeAcceptingAnother =>
      'Finish your current trip before accepting another.';

  @override
  String get fixedFare => 'Fixed fare';

  @override
  String fixedFareAcceptedCancellationPaymentPolicyV1AcceptedValue(
    String value,
  ) {
    return 'Fixed fare ₱$value accepted; cancellation/payment policy v1 accepted.';
  }

  @override
  String get fixedFareForThisRoute => 'Fixed fare for this route';

  @override
  String get fixedFares => 'Fixed fares';

  @override
  String get fixedFaresSavedExistingBookingPricesAreUnchanged =>
      'Fixed fares saved. Existing booking prices are unchanged.';

  @override
  String fixedFareValue(String value) {
    return 'Fixed fare: ₱$value';
  }

  @override
  String get fixedItinerary => 'Fixed itinerary';

  @override
  String get flag => 'Flag';

  @override
  String flutterFailureValue(String value) {
    return 'Flutter failure: $value';
  }

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get forgotPasswordLabel => 'Forgot password?';

  @override
  String forImmediateDangerCall911AppDoesNotReplaceEmergencyServices(
    String brandName,
  ) {
    return 'For immediate danger, call 911. $brandName does not replace emergency services.';
  }

  @override
  String get formattedValue => ' → ';

  @override
  String get fr12345 => 'FR-12345';

  @override
  String get franchise => 'Franchise';

  @override
  String get franchiseExpiresOn => 'franchise_expires_on';

  @override
  String get franchiseExpiryDate => 'Franchise expiry date';

  @override
  String get franchiseNumber => 'Franchise number';

  @override
  String get franchiseNumberIsRequired => 'Franchise Number is required';

  @override
  String get franchiseOrCr => 'Franchise / OR-CR';

  @override
  String get franchiseOrCrDocumentIsMissing =>
      'Franchise / OR-CR document is missing.';

  @override
  String get franchiseOrCrExpiry => 'Franchise / OR-CR expiry';

  @override
  String get franchiseOrCrLabel => 'Franchise OR/CR';

  @override
  String get franchiseOrCrNumberIsRequired =>
      'Franchise/OR-CR number is required';

  @override
  String franchiseOrCrNumberMustNotExceedCharactersValue(String value) {
    return 'Franchise/OR-CR number must not exceed $value characters';
  }

  @override
  String franchiseValue(String value) {
    return 'Franchise: $value';
  }

  @override
  String get freeCancellation => 'Free cancellation';

  @override
  String
  freeCancellationMinutesLateTouristCancellationVerifiedPickupWaitMinutesTouristNoShowValue(
    String value,
    String secondValue,
    String thirdValue,
    String fourthValue,
  ) {
    return 'Free cancellation: $value minutes\nLate tourist cancellation: $secondValue%\nVerified pickup wait: $thirdValue minutes\nTourist no-show fee: $fourthValue%\n\nExisting bookings keep their original policy.';
  }

  @override
  String get fri => 'Fri';

  @override
  String get fromPickup => 'from pickup';

  @override
  String fromValue(String value, String secondValue) {
    return '$value from $secondValue';
  }

  @override
  String get fromYou => 'from you';

  @override
  String get fulfilled => 'fulfilled';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameIsRequired => 'Full name is required';

  @override
  String get getAroundQuicklyAndSafelyByBookingLocalTricycleDriversInSeconds =>
      'Get around quickly and safely by booking local tricycle drivers in seconds.';

  @override
  String get getStarted => 'Get started';

  @override
  String get goBack => 'Go back';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get goodMorning => 'Good morning';

  @override
  String goodMorningValue(String value) {
    return 'Good morning, $value';
  }

  @override
  String get goOnlineToActivateTheDriverMap =>
      'Go online to activate the driver map.';

  @override
  String get goOnlineToStartReceivingBookingRequests =>
      'Go online to start receiving booking requests.';

  @override
  String get goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept =>
      'Go online with an approved account and finish your current trip to accept a new request.';

  @override
  String get goOnlineWithAnApprovedDriverAccountFirst =>
      'Go online with an approved driver account first.';

  @override
  String get greatRideVeryKnowledgeableAboutBustos =>
      'Great ride, very knowledgeable about Bustos!';

  @override
  String get headingTo => 'Heading to';

  @override
  String get headingToPickup => 'Heading to Pickup';

  @override
  String get help => 'Help';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get heritage => 'Heritage';

  @override
  String get hidden => 'HIDDEN';

  @override
  String hideValue(String value) {
    return 'Hide $value';
  }

  @override
  String get history => 'History';

  @override
  String hoursAgoValue(String value) {
    return '$value hours ago';
  }

  @override
  String howWasYourRideWithValue(String value) {
    return 'How was your ride with $value?';
  }

  @override
  String get iAgreeToTheFixedFareAndCancellationPaymentPolicy =>
      'I agree to the fixed fare and cancellation/payment policy.';

  @override
  String get iAgreeToTheTermsAndConditions =>
      'I agree to the Terms and Conditions';

  @override
  String get iAmA => 'I am a...';

  @override
  String get ifPlansChange => 'If plans change';

  @override
  String get iHaveReadAndAcceptThisNotice =>
      'I have read and accept this notice.';

  @override
  String get iHaveReadTheNoticeAndAgreeToTheDataUseNeededTo =>
      'I have read the notice and agree to the data use needed to provide my account and trips.';

  @override
  String get imageContentMimeTypeAndFileExtensionMustMatch =>
      'Image content, MIME type and file extension must match.';

  @override
  String get includedStops => 'Included stops';

  @override
  String
  get includeWhatHappenedWhereTheTripStoppedAndAnyCashAlreadyExchangedStatements =>
      'Include what happened, where the trip stopped, and any cash already exchanged. Statements are retained with the booking.';

  @override
  String get incomingBooking => 'Incoming booking';

  @override
  String get incomingPickup => 'Incoming pickup';

  @override
  String informationProvidedByAppAdministrators(String brandName) {
    return 'Information provided by $brandName administrators';
  }

  @override
  String get interactiveMapsAreAvailableInTheMobileApp =>
      'Interactive maps are available in the mobile app.';

  @override
  String get invalidAdminCredentials => 'Invalid admin credentials';

  @override
  String get invalidAppBuild => 'Invalid app build';

  @override
  String get invalidAttractionImageOwner => 'Invalid attraction image owner.';

  @override
  String get invalidAttractionImageVersion =>
      'Invalid attraction image version.';

  @override
  String get invalidLatitude => 'Invalid latitude';

  @override
  String get invalidLongitude => 'Invalid longitude';

  @override
  String isExpiredValue(String value) {
    return '$value is expired.';
  }

  @override
  String isNowHiddenValue(String value) {
    return '$value is now hidden';
  }

  @override
  String isNowVisibleValue(String value) {
    return '$value is now visible';
  }

  @override
  String isRequiredValue(String value) {
    return '$value is required';
  }

  @override
  String isTemporarilyClosedAndCannotBeAddedRightNow(String spot) {
    return '$spot is temporarily closed and cannot be added right now.';
  }

  @override
  String get itinerary => 'Itinerary';

  @override
  String get iVerifiedThisNumberWithTheAgency =>
      'I verified this number with the agency.';

  @override
  String get jan => 'Jan';

  @override
  String get jobs => 'Jobs';

  @override
  String get johnDoe => 'John doe';

  @override
  String get johnExampleCom => 'john@example.com';

  @override
  String get juanDelaCruz => 'Juan Dela Cruz';

  @override
  String get juanExampleCom => 'juan@example.com';

  @override
  String get jul => 'Jul';

  @override
  String get jun => 'Jun';

  @override
  String get justNow => 'Just now';

  @override
  String get keepAccount => 'Keep account';

  @override
  String get keepCurrentCode => 'Keep current code';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get keepOpen => 'Keep open';

  @override
  String get keepOriginalRoute => 'Keep original route';

  @override
  String get keepUnderReview => 'Keep under review';

  @override
  String get keepWaiting => 'Keep waiting';

  @override
  String kmAwayValue(String value, String secondValue) {
    return '$value • $secondValue km away';
  }

  @override
  String kmAwayValueLabel(String value) {
    return '$value km away';
  }

  @override
  String kmValue(String value) {
    return ' ${value}km';
  }

  @override
  String get language => 'Language';

  @override
  String get lastLocationIsMoreThanAMinuteOld =>
      'Last location is more than a minute old';

  @override
  String get lateCancellation => 'Late cancellation';

  @override
  String get lateCancellationFee => 'Late cancellation fee';

  @override
  String get latitude => 'Latitude';

  @override
  String get leaveACommentOptional => 'Leave a comment (Optional)';

  @override
  String get leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder =>
      'Leave the number empty to keep a clearly marked placeholder.';

  @override
  String get licenseExpiresOn => 'license_expires_on';

  @override
  String get licenseExpiryDate => 'License expiry date';

  @override
  String get licenseImageSelected => 'License image selected';

  @override
  String licenseValue(String value) {
    return 'License: $value';
  }

  @override
  String get listView => 'List view';

  @override
  String get liveDriverTracking => 'Live driver tracking';

  @override
  String get liveLocationIsActiveForTripMatching =>
      'Live location is active for trip matching';

  @override
  String get liveLocationIsReconnectingKeepTheAppOpen =>
      'Live location is reconnecting. Keep the app open.';

  @override
  String get liveMapboxTrackingIsAvailableInTheMobileApp =>
      'Live Mapbox tracking is available in the mobile app.';

  @override
  String get liveOverview => 'Live overview';

  @override
  String get loading => 'Loading';

  @override
  String get loadingMore => 'Loading more…';

  @override
  String get loadMore => 'Load more';

  @override
  String get loadMoreBookings => 'Load more bookings';

  @override
  String get loadMorePeople => 'Load more people';

  @override
  String get localContactsAndSos => 'Local contacts and SOS';

  @override
  String get localEmergencyNumbers => 'Local emergency numbers';

  @override
  String get localHistory => 'Local history';

  @override
  String get localRoadsArePreferredFollowRoadSignsAndYourApprovedTodaOrLgu =>
      'Local roads are preferred. Follow road signs and your approved TODA or LGU route.';

  @override
  String get locationIsUnavailableRightNowCheckYourSettingsAndTryAgain =>
      'Location is unavailable right now. Check your settings and try again.';

  @override
  String get locationPermissionDeniedEnableItInSettings =>
      'Location permission denied. Enable it in Settings.';

  @override
  String get locationPermissionIsNeededToReceiveRides =>
      'Location permission is needed to receive rides.';

  @override
  String get locationPermissionIsNeededToUseYourCurrentPosition =>
      'Location permission is needed to use your current position.';

  @override
  String get locationServicesAreDisabledPleaseEnableGps =>
      'Location services are disabled. Please enable GPS.';

  @override
  String get locationSharingIsAlreadyStopped =>
      'Location sharing is already stopped.';

  @override
  String get locationSharingIsNoLongerAvailableOnThisScreen =>
      'Location sharing is no longer available on this screen.';

  @override
  String get locationSharingIsOff => 'Location sharing is off';

  @override
  String get locationSharingWasCancelled => 'Location sharing was cancelled.';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get login => 'Login';

  @override
  String get loginAsAdmin => 'Login as Admin';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutLabel => 'Log out?';

  @override
  String get longitude => 'Longitude';

  @override
  String get lookingForADriver => 'Looking for a driver';

  @override
  String get lostPickupCodeReissue => 'Lost pickup code? Reissue';

  @override
  String get luggageOrBulkyItems => 'Luggage or bulky items';

  @override
  String get makeItYourOwn => 'Make it your own';

  @override
  String manageAppOpenTheAdminPortal(String brandName) {
    return 'Manage $brandName? Open the admin portal';
  }

  @override
  String get manageTourists => 'Manage tourists';

  @override
  String get mapView => 'Map view';

  @override
  String get mar => 'Mar';

  @override
  String get mariaExampleCom => 'maria@example.com';

  @override
  String get markAllAsRead => 'Mark all as read';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get market => 'Market';

  @override
  String get matchingBlockers => 'Matching blockers';

  @override
  String get matchingIsTemporarilyBlocked => 'Matching is temporarily blocked.';

  @override
  String get matchWithTouristsWhoDescribeMobilityOrBoardingNeeds =>
      'Match with tourists who describe mobility or boarding needs.';

  @override
  String get maximumCapacityIsCheckedBeforeOfferingTheBooking =>
      'Maximum capacity is checked before offering the booking.';

  @override
  String get may => 'May';

  @override
  String get member => 'Member';

  @override
  String get message => 'Message';

  @override
  String get min8Characters => 'Min. 8 characters';

  @override
  String get min8Chars => 'Min. 8 chars';

  @override
  String minsAgoValue(String value) {
    return '$value mins ago';
  }

  @override
  String get minutes => 'minutes';

  @override
  String minValue(String value, String secondValue) {
    return '$value | $secondValue min';
  }

  @override
  String minValueLabel(String value, String secondValue) {
    return '$value min | $secondValue';
  }

  @override
  String missingValue(String value) {
    return '$value missing';
  }

  @override
  String modeValue(String value) {
    return '$value mode';
  }

  @override
  String modeValueLabel(String value, String secondValue, String thirdValue) {
    return '$value · $secondValue mode\n$thirdValue';
  }

  @override
  String get mon => 'Mon';

  @override
  String get moveTheMapPinOrUseYourCurrentLocationBeforeSaving =>
      'Move the map pin or use your current location before saving.';

  @override
  String mustBeAtLeastCharactersValue(String value, String secondValue) {
    return '$value must be at least $secondValue characters';
  }

  @override
  String mustNotExceedCharactersValue(String value, String secondValue) {
    return '$value must not exceed $secondValue characters';
  }

  @override
  String get myBookings => 'My bookings';

  @override
  String get myData => 'My data';

  @override
  String get myLocation => 'My location';

  @override
  String get name => 'Name';

  @override
  String get nameMustBeAtLeast2Characters =>
      'Name must be at least 2 characters';

  @override
  String nameMustNotExceedCharactersValue(String value) {
    return 'Name must not exceed $value characters';
  }

  @override
  String get namePlateFranchiseOrServiceArea =>
      'Name, plate, franchise, or service area';

  @override
  String get nationalEmergencyHotline => 'National emergency hotline';

  @override
  String get nature => 'Nature';

  @override
  String get navigate => 'Navigate';

  @override
  String get needsReview => 'Needs review';

  @override
  String get newPassword => 'New password';

  @override
  String get newRideRequest => 'New ride request';

  @override
  String get next => 'Next';

  @override
  String get noActiveBookingOpenTripsToViewYourHistory =>
      'No active booking. Open Trips to view your history.';

  @override
  String get noActiveTrip => 'No active trip';

  @override
  String get noActiveTrips => 'No active trips';

  @override
  String get noArrivalIsAwaitingConfirmation =>
      'No arrival is awaiting confirmation.';

  @override
  String get noBlockedDrivers => 'No blocked drivers';

  @override
  String get noBookingsHereYet => 'No bookings here yet.';

  @override
  String get noBookingsInThisCategory => 'No bookings in this category.';

  @override
  String get noCharge => 'No charge';

  @override
  String get noCompletedBookingsFoundForThisPeriod =>
      'No completed bookings found for this period.';

  @override
  String get noCompletedDriverTripsYet => 'No completed driver trips yet.';

  @override
  String get noConfirmedMoneyMovementYet => 'No confirmed money movement yet.';

  @override
  String get noDestinationsSelected => 'No destinations selected';

  @override
  String
  get noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate =>
      'No distance, waiting or surge additions. Entrance fees and purchases are separate.';

  @override
  String get noDriverAcceptedDuringThisSearchWindowRetryToOpenAFreshRequest =>
      'No driver accepted during this search window. Retry to open a fresh request or cancel without charge.';

  @override
  String get noDriversAwaitingReview => 'No drivers awaiting review';

  @override
  String get noDriverYet => 'No driver yet';

  @override
  String get noEligibleActiveDrivers => 'No eligible active drivers';

  @override
  String get noEndedTripsInThisPeriod => 'No ended trips in this period.';

  @override
  String get noExportRequestsYet => 'No export requests yet.';

  @override
  String get noLocalRoadRouteWasReturned => 'No local-road route was returned.';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noPastTripsYet => 'No past trips yet';

  @override
  String get noPendingRequest => 'No pending request';

  @override
  String get noPhotosAvailable => 'No photos available';

  @override
  String get noRecentBookings => 'No recent bookings';

  @override
  String get noReviewsFound => 'No reviews found.';

  @override
  String get noShowFee => 'No-show fee';

  @override
  String get noSpotsFound => 'No spots found';

  @override
  String get noSystemFeedbackFound => 'No system feedback found.';

  @override
  String get notificationDeliveryFailures => 'Notification delivery failures';

  @override
  String get notifications => 'Notifications';

  @override
  String get noTouristsFound => 'No tourists found';

  @override
  String get noTouristSpotsFound => 'No tourist spots found.';

  @override
  String get notRated => 'Not rated';

  @override
  String get notVerified => 'Not verified';

  @override
  String get notYet => 'Not yet';

  @override
  String get nov => 'Nov';

  @override
  String get noVerifiedContactNumberIsAvailableForThisTourist =>
      'No verified contact number is available for this tourist.';

  @override
  String get oct => 'Oct';

  @override
  String get officialEmergencyNumbersFromMunicipalityPortal =>
      'Official emergency numbers from municipality portal.';

  @override
  String get offline => 'Offline';

  @override
  String get offlineConnection => 'Offline connection';

  @override
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnection(
    String time,
  ) {
    return 'Offline mode · showing saved data from $time. Critical actions require a connection.';
  }

  @override
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnectionValue(
    String value,
  ) {
    return 'Offline mode · showing saved data from $value. Critical actions require a connection.';
  }

  @override
  String get offlineSavedInformationMayBeShown =>
      'Offline · saved information may be shown.';

  @override
  String
  get offThePlannedRouteNavigationIsRecalculatingFollowLegalLocalRoadsAndStop =>
      'Off the planned route · navigation is recalculating. Follow legal local roads and stop safely if unsure.';

  @override
  String get onePriceForTheBookedRoute => 'One price for the booked route';

  @override
  String get ongoing => 'ongoing';

  @override
  String get online => 'Online';

  @override
  String get onlinePayment => 'Online payment';

  @override
  String get onlinePaymentFailedRetryAvailable =>
      'Online payment failed — retry available';

  @override
  String get onlinePaymentNotStarted => 'Online payment not started';

  @override
  String get onlinePaymentReceived => 'Online payment received';

  @override
  String get onlinePaymentRequiresTheConfiguredServer =>
      'Online payment requires the configured server.';

  @override
  String get onlinePaymentsRequireAVerifiedPaymentProvider =>
      'Online payments require a verified payment provider.';

  @override
  String get onlineRefundAwaitingAdminAction =>
      'Online refund awaiting admin action';

  @override
  String get onlineRefundDue => 'Online refund due';

  @override
  String get onlyACompletedUnratedTripCanBeReviewed =>
      'Only a completed, unrated trip can be reviewed.';

  @override
  String get onlyAnAcceptedBookingCanStart =>
      'Only an accepted booking can start.';

  @override
  String get onlyAnEndedTripWithAnOpenReviewCanBeResolved =>
      'Only an ended trip with an open review can be resolved.';

  @override
  String get onlyAnOngoingTripCanBeCompleted =>
      'Only an ongoing trip can be completed.';

  @override
  String get onlyAParticipantCanReportAPaymentIssue =>
      'Only a participant can report a payment issue.';

  @override
  String get onlyAPendingDriverApplicationCanBeResumedFromThisForm =>
      'Only a pending driver application can be resumed from this form.';

  @override
  String get onlyATripParticipantCanEndThisTrip =>
      'Only a trip participant can end this trip.';

  @override
  String get onlyThePayerAndReceiverCanConfirmCash =>
      'Only the payer and receiver can confirm cash.';

  @override
  String
  get onlyUnvisitedStopsMoveTheOtherParticipantMustApproveBeforeNavigationChanges =>
      'Only unvisited stops move. The other participant must approve before navigation changes.';

  @override
  String get openAPaymentReview => 'Open a payment review';

  @override
  String get openAppStore => 'Open app store';

  @override
  String openAppToViewThisUpdate(String brandName) {
    return 'Open $brandName to view this update.';
  }

  @override
  String get openDialer => 'OPEN DIALER';

  @override
  String get openDriverSearch => 'Open driver search';

  @override
  String get openingHours => 'Opening hours';

  @override
  String openReviewsValue(String value) {
    return 'Open reviews: $value';
  }

  @override
  String get openTheMobileAppForTheInteractiveRoute =>
      'Open the mobile app for the interactive route.';

  @override
  String get openTripMap => 'Open trip map';

  @override
  String get openTripsToSeeTheLatestBookingStatus =>
      'Open Trips to see the latest booking status.';

  @override
  String operationalAlertSNeedReviewValue(String value) {
    return '$value operational alert(s) need review';
  }

  @override
  String operationFailureValue(String value) {
    return 'Operation failure: $value';
  }

  @override
  String get operationsCentre => 'Operations centre';

  @override
  String get other => 'Other';

  @override
  String get overview => 'Overview';

  @override
  String get packageNotFound => 'Package not found.';

  @override
  String get packageStopsChangedSelectThePackageAgain =>
      'Package stops changed. Select the package again.';

  @override
  String get paid => 'paid';

  @override
  String get paidOnline => 'Paid online';

  @override
  String get park => 'Park';

  @override
  String get partiallypaid => 'partiallyPaid';

  @override
  String get partiallyRefunded => 'Partially refunded';

  @override
  String get passengerCapacity => 'Passenger capacity';

  @override
  String passengerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
    );
    return '$_temp0';
  }

  @override
  String get passengerRequirements => 'Passenger requirements';

  @override
  String get passengers => 'Passengers';

  @override
  String passengersValue(String value) {
    return '$value passengers';
  }

  @override
  String get password => 'Password';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get passwordMustBeAtLeast8Characters =>
      'Password must be at least 8 characters';

  @override
  String get passwordMustContainAtLeastOneNumber =>
      'Password must contain at least one number';

  @override
  String get passwordMustContainAtLeastOneUppercaseLetter =>
      'Password must contain at least one uppercase letter';

  @override
  String passwordMustNotExceedCharactersValue(String value) {
    return 'Password must not exceed $value characters';
  }

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordUpdatedSignInAgain => 'Password updated. Sign in again.';

  @override
  String get past => 'Past';

  @override
  String get pauseForAVehicleProblem => 'Pause for a vehicle problem?';

  @override
  String get paymentAttention => 'Payment attention';

  @override
  String paymentDisputedValue(String value) {
    return 'Payment disputed: $value';
  }

  @override
  String get paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr =>
      'Payment is on hold. An admin must review the case before collection or a cash return.';

  @override
  String
  get paymentIsPendingADriverWillOnlyBeRequestedAfterPaymentIsConfirmed =>
      'Payment is pending. A driver will only be requested after payment is confirmed. Unpaid requests expire after 30 minutes.';

  @override
  String get paymentOnHoldAdminReview => 'Payment on hold · admin review';

  @override
  String get paymentpending => 'paymentPending';

  @override
  String get paymentPending => 'Payment pending';

  @override
  String get paymentPendingLabel => 'payment_pending';

  @override
  String get paymentReview => 'payment review';

  @override
  String get paymentReviewPending => 'Payment review pending';

  @override
  String get paymentStatusCouldNotBeRefreshed =>
      'Payment status could not be refreshed.';

  @override
  String get paymentStatusRefreshed => 'Payment status refreshed.';

  @override
  String get paymentStatusUnavailableRefreshOrUpdateTheApp =>
      'Payment status unavailable. Refresh or update the app.';

  @override
  String get paymentVerificationRequiresTheConfiguredServer =>
      'Payment verification requires the configured server.';

  @override
  String get paymongo => 'PayMongo';

  @override
  String get paymongoCheckoutReady => 'PayMongo checkout ready';

  @override
  String get paymongoIsProcessingPayment => 'PayMongo is processing payment';

  @override
  String get paymongoTestModeStatusIsConfirmedByWebhookOrADirectProviderCheck =>
      'PayMongo test mode · status is confirmed by webhook or a direct provider check.';

  @override
  String get paymongoUnavailable => 'PayMongo unavailable';

  @override
  String get payTheFinalAmountAfterTheTripTouristAndDriverMustBothConfirm =>
      'Pay the final amount after the trip. Tourist and driver must both confirm the cash handover.';

  @override
  String get pending => 'Pending';

  @override
  String
  get pendingRequestsAndDriverCancellationsAreFreeTouristCancellationAfterTheGracePeriod =>
      'Pending requests and driver cancellations are free. Tourist cancellation after the grace period may incur the published fee. A no-show requires verified driver arrival and the full waiting period.';

  @override
  String get permanentlyDelete => 'Permanently delete';

  @override
  String get personalInfo => 'Personal info';

  @override
  String get personalInformation => 'Personal information';

  @override
  String get phone => 'Phone';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberIsRequired => 'Phone number is required';

  @override
  String get photoGallery => 'Photo gallery';

  @override
  String get photos => 'Photos';

  @override
  String get pickupArrivalCanOnlyBeReportedForAnAcceptedBooking =>
      'Pickup arrival can only be reported for an accepted booking.';

  @override
  String get pickupArrivalHasAlreadyBeenRecorded =>
      'Pickup arrival has already been recorded.';

  @override
  String get pickupCode => 'Pickup code';

  @override
  String get pickupCodeVerifiedTripStarted =>
      'Pickup code verified; trip started.';

  @override
  String get pickupLocationPreview => 'Pickup location preview';

  @override
  String get pickupPoint => 'Pickup point';

  @override
  String pickupValue(String value) {
    return 'Pickup: $value';
  }

  @override
  String get pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain =>
      'Pickup verification is temporarily locked. Please wait and try again.';

  @override
  String get pickupWait => 'Pickup wait';

  @override
  String get placeholderTheOwnerMustVerifyAndEnterANumber =>
      'Placeholder — the owner must verify and enter a number.';

  @override
  String get places => 'Places';

  @override
  String get placesYouSaved => 'Places you saved';

  @override
  String get planYourTrip => 'Plan your trip';

  @override
  String get plateNumber => 'Plate number';

  @override
  String get plateNumberIsRequired => 'Plate number is required';

  @override
  String plateNumberMustNotExceedCharactersValue(String value) {
    return 'Plate number must not exceed $value characters';
  }

  @override
  String platformFailureValue(String value) {
    return 'Platform failure: $value';
  }

  @override
  String get pleaseConfirmYourPassword => 'Please confirm your password';

  @override
  String get pleaseDescribeYourConcernOrSuggestionInDetail =>
      'Please describe your concern or suggestion in detail...';

  @override
  String get pleaseEnterAtLeast20Characters =>
      'Please enter at least 20 characters.';

  @override
  String get pleaseEnterAValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get pleaseEnterAValidPlateNumber =>
      'Please enter a valid plate number';

  @override
  String get pleaseEnterYourStreetOrHouseNumber =>
      'Please enter your street or house number';

  @override
  String get pleaseExplainTheIssueAtLeast5Characters =>
      'Please explain the issue (at least 5 characters).';

  @override
  String get pleaseGiveAReasonAtLeast5Characters =>
      'Please give a reason (at least 5 characters).';

  @override
  String get pleaseProvideDetailsAtLeast5Characters =>
      'Please provide details (at least 5 characters).';

  @override
  String get pleaseReviewTheCurrentPrivacyNotice =>
      'Please review the current privacy notice';

  @override
  String get pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode =>
      'Please wait five minutes before requesting another pickup code.';

  @override
  String get policyPublishedExistingBookingsAreUnchanged =>
      'Policy published. Existing bookings are unchanged.';

  @override
  String policyVersionValue(String value) {
    return 'Policy version $value';
  }

  @override
  String get prepareExport => 'Prepare export';

  @override
  String get preparePrivateAccountExports => 'Prepare private account exports';

  @override
  String get preparingDriverRoute => 'Preparing driver route';

  @override
  String get preparingRoute => 'Preparing route...';

  @override
  String get pressSosToOpenYourPhoneDialerWithTheNationalEmergencyNumber =>
      'Press SOS to open your phone dialer with the national emergency number.';

  @override
  String get previewAnnouncement => 'Preview announcement';

  @override
  String priceHistoryCurrentVersionValue(String value) {
    return 'Price history · current version $value';
  }

  @override
  String get pricesChangedWhileYouWereEditingReopenThisPageAndReviewTheLatest =>
      'Prices changed while you were editing. Reopen this page and review the latest rates.';

  @override
  String get priceVersion => 'Price version';

  @override
  String get privacyAndDataUse => 'Privacy and data use';

  @override
  String get privacyNoticeAcceptanceIsRequired =>
      'Privacy notice acceptance is required.';

  @override
  String get privacyUpdate => 'Privacy update';

  @override
  String get profileImagesMustBe5MbOrSmaller =>
      'Profile images must be 5 MB or smaller.';

  @override
  String get profileImagesMustBeJpegOrPngFiles =>
      'Profile images must be JPEG or PNG files.';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get profileUpdatedSuccessfullyLabel => 'Profile updated successfully!';

  @override
  String get proposeANewStopOrder => 'Propose a new stop order';

  @override
  String proposedValue(String value) {
    return 'Proposed: $value';
  }

  @override
  String get publish => 'Publish';

  @override
  String get publishCancellationPolicy => 'Publish cancellation policy?';

  @override
  String get publishedPolicy => 'Published policy';

  @override
  String get publishing => 'Publishing...';

  @override
  String get publishPolicy => 'Publish policy';

  @override
  String get publishTheseFixedFares => 'Publish these fixed fares?';

  @override
  String get radius130Km => 'Radius (1–30 km)';

  @override
  String get rateDriver => 'Rate driver';

  @override
  String get rating => 'Rating';

  @override
  String get ratingsFeedback => 'Ratings & Feedback';

  @override
  String get ratingsReviews => 'Ratings & Reviews';

  @override
  String get readyForApproval => 'Ready for approval';

  @override
  String get readyMadeDaysOut => 'Ready-made days out';

  @override
  String get readyMadeTrips => 'Ready-made trips';

  @override
  String get reason => 'Reason';

  @override
  String get reasonAtLeast5Characters => 'Reason (at least 5 characters)';

  @override
  String get reasonDetails => 'Reason / details';

  @override
  String get reasonForChangingTheOrder => 'Reason for changing the order';

  @override
  String get reasonForPolicyChange => 'Reason for policy change';

  @override
  String get reasonForPriceChange => 'Reason for price change';

  @override
  String get receiveBookingsEarnMoneyAndShowcaseYourLocalKnowledge =>
      'Receive bookings, earn money, and showcase your local knowledge.';

  @override
  String get recentBookings => 'Recent bookings';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshPaymentStatus => 'Refresh payment status';

  @override
  String get refundCompleted => 'Refund completed';

  @override
  String get refundCompletedInPaymongoTestMode =>
      'Refund completed in PayMongo test mode.';

  @override
  String get refundCompletedInTheTestPaymentEnvironment =>
      'Refund completed in the test payment environment.';

  @override
  String get refundDecisionRecorded => 'Refund decision recorded.';

  @override
  String get refunddue => 'refundDue';

  @override
  String get refunded => 'refunded';

  @override
  String get refundRequired => 'refund_required';

  @override
  String get refundSentAwaitingPaymongoConfirmation =>
      'Refund sent · awaiting PayMongo confirmation';

  @override
  String get refundUpdateRecorded => 'Refund update recorded.';

  @override
  String get register => 'Register';

  @override
  String get registrationDidNotComplete => 'Registration did not complete.';

  @override
  String get reissueCode => 'Reissue code';

  @override
  String get reissuePickupCode => 'Reissue pickup code?';

  @override
  String get reject => 'Reject';

  @override
  String get rejectApplication => 'Reject application';

  @override
  String get rejected => 'Rejected';

  @override
  String releaseConfigurationIsIncompleteValue(String value) {
    return 'Release configuration is incomplete: $value';
  }

  @override
  String get reliability => 'Reliability';

  @override
  String reliabilitySeatsValue(String value, String secondValue) {
    return '$value% reliability • $secondValue seats';
  }

  @override
  String reliableValue(String value) {
    return '$value% reliable';
  }

  @override
  String get removedFromYourItinerary => 'Removed from your itinerary';

  @override
  String get removeDuplicateDestinations => 'Remove duplicate destinations.';

  @override
  String get reopenAttraction => 'Reopen attraction';

  @override
  String reopenedValue(String value) {
    return '$value reopened';
  }

  @override
  String get replacementNeeded => 'REPLACEMENT NEEDED';

  @override
  String get replacementpending => 'replacementPending';

  @override
  String get replacementPending => 'replacement_pending';

  @override
  String get reportArrivalAtNextStop => 'Report arrival at next stop';

  @override
  String get reports => 'Reports';

  @override
  String get reportsAnalytics => 'Reports & Analytics';

  @override
  String get reportTouristNoShow => 'Report tourist no-show?';

  @override
  String get reportTouristNoShowLabel => 'Report tourist no-show';

  @override
  String get reportYourVerifiedArrivalAtThePickupPointBeforeStarting =>
      'Report your verified arrival at the pickup point before starting.';

  @override
  String get requestACopyOfYourAccountAndTripDataSupportPreparesTheExport =>
      'Request a copy of your account and trip data. Support prepares the export for your account only.';

  @override
  String get requestADifferentStopOrder => 'Request a different stop order';

  @override
  String get requestADriverNow => 'Request a driver now';

  @override
  String get requestAnotherDriver => 'Request another driver?';

  @override
  String get requestDataExport => 'Request data export';

  @override
  String get requestIsNoLongerPending => 'Request is no longer pending';

  @override
  String get requests => 'Requests';

  @override
  String get requestSaved => 'Request saved';

  @override
  String get requestToSkipThisStop => 'Request to skip this stop';

  @override
  String requestToSkipValue(String value) {
    return 'Request to skip $value?';
  }

  @override
  String get resetMap => 'Reset map';

  @override
  String get resolve => 'Resolve';

  @override
  String get resolved => 'Resolved';

  @override
  String get resolvePaymentReview => 'Resolve payment review';

  @override
  String get resortCaf => 'Resort & Café';

  @override
  String get respondToCommunityConcerns => 'Respond to community concerns';

  @override
  String get restore => 'Restore';

  @override
  String get restoreTourist => 'Restore tourist?';

  @override
  String get resumePayment => 'Resume payment';

  @override
  String get retry => 'Retry';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get retrying => 'Retrying…';

  @override
  String get retryStorage => 'Try again';

  @override
  String get retypePassword => 'Retype password';

  @override
  String get revenueOverTime => 'Revenue over time';

  @override
  String get review => 'Review';

  @override
  String get reviewActiveAndCompletedTrips =>
      'Review active and completed trips';

  @override
  String get reviewAndPublishFares => 'Review and publish fares';

  @override
  String get reviewAndPublishPolicy => 'Review and publish policy';

  @override
  String get reviewCountSummary => '(128 reviews)';

  @override
  String get reviewFailuresAndStaleDrivers =>
      'Review failures and stale drivers';

  @override
  String get reviewFare => 'Review fare';

  @override
  String get reviewFlaggedForFollowUp => 'Review flagged for follow-up';

  @override
  String get reviewNote => 'Review note';

  @override
  String get reviewPendingDrivers => 'Review pending drivers';

  @override
  String reviewResolvedFinalChargeValue(String value, String secondValue) {
    return 'Review resolved: ₱$value final charge. $secondValue';
  }

  @override
  String get reviews => 'Reviews';

  @override
  String get reviewYourBooking => 'Review your booking';

  @override
  String get ride => 'Ride';

  @override
  String get rideAndBookingUpdates => 'Ride and booking updates';

  @override
  String get rideUpdates => 'Ride updates';

  @override
  String get roadRouteUnavailableCheckYourConnectionAndTryAgain =>
      'Road route unavailable. Check your connection and try again.';

  @override
  String routeProgressConfirmedValue(String value, String secondValue) {
    return 'Route progress · $value/$secondValue confirmed';
  }

  @override
  String get routeReorderApprovalNeeded => 'Route reorder approval needed';

  @override
  String get safeCapacity => 'Safe capacity';

  @override
  String get safeDriver => 'Safe driver';

  @override
  String get safePassengerCapacity => 'Safe passenger capacity';

  @override
  String get safetySupport => 'Safety & support';

  @override
  String get sanPedro => 'San pedro';

  @override
  String get sat => 'Sat';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saved => 'Saved';

  @override
  String get saveDecision => 'Save decision';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get savedTripDataCouldNotBeReadBookingChangesArePausedToProtect =>
      'Saved trip data could not be read. Booking changes are paused to protect your records. Retry storage or restart the app.';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get savePlacesYouLove => 'Save places you love';

  @override
  String get saveReviewWithoutApproval => 'Save review without approval';

  @override
  String get saveSpot => 'Save spot';

  @override
  String get saving => 'Saving…';

  @override
  String get savingBooking => 'Saving booking…';

  @override
  String get scheduled => 'scheduled';

  @override
  String get scheduledFor => 'Scheduled for';

  @override
  String get scheduledJobFailures => 'Scheduled job failures';

  @override
  String get scheduledPickup => 'Scheduled pickup';

  @override
  String get schedulePickupAtLeast1HourFromNow =>
      'Schedule pickup at least 1 hour from now.';

  @override
  String get search => 'Search';

  @override
  String get searchAgain => 'Search again';

  @override
  String get searchDrivers => 'Search drivers';

  @override
  String get searchSpots => 'Search spots...';

  @override
  String get searchWindowEnded => 'Search window ended';

  @override
  String get secureYourAccount => 'Secure your account';

  @override
  String get seeAll => 'See all';

  @override
  String get seeYourDailyTripSummary => 'See your daily trip summary';

  @override
  String get selectAddress => 'Select address';

  @override
  String get selectARatingBetween1And5 => 'Select a rating between 1 and 5.';

  @override
  String get selectAtLeastOneDestinationFirst =>
      'Select at least one destination first.';

  @override
  String get selectBetween1And12Destinations =>
      'Select between 1 and 12 destinations.';

  @override
  String get selectedStop => 'Selected stop';

  @override
  String get selectExpiryDate => 'Select expiry date';

  @override
  String get sendAnAnnouncement => 'Send an announcement';

  @override
  String get sendAnnouncement => 'Send announcement';

  @override
  String get sendASupportMessage => 'Send a support message';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendProposal => 'Send proposal';

  @override
  String get sendRefundRequestToPaymongo => 'Send refund request to PayMongo';

  @override
  String get sendRefundToPaymongo => 'Send refund to PayMongo?';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get sep => 'Sep';

  @override
  String get serverSetupIsIncomplete => 'Server setup is incomplete.';

  @override
  String
  get serverSetupIsIncompleteAddTheSupabaseBuildConfigurationBeforeSigningIn =>
      'Server setup is incomplete. Add the Supabase build configuration before signing in.';

  @override
  String get serverSetupIsIncompleteFeedbackWasNotSent =>
      'Server setup is incomplete. Feedback was not sent.';

  @override
  String get serverSetupIsIncompleteNothingWasSent =>
      'Server setup is incomplete. Nothing was sent.';

  @override
  String get serverSetupIsIncompleteTheAttractionWasNotSaved =>
      'Server setup is incomplete. The attraction was not saved.';

  @override
  String serviceAreaValue(String value) {
    return 'Service area: $value ';
  }

  @override
  String get serviceHealth => 'Service health';

  @override
  String get sessionChanged => 'Session changed.';

  @override
  String get setAFlatCustomTourFareAndAFixedFareForEachPackage =>
      'Set a flat custom-tour fare and a fixed fare for each package. No automatic per-stop, distance, waiting-time or surge additions. Entrance fees are paid separately.';

  @override
  String get shareAnUpdateWithDriversOrTourists =>
      'Share an update with drivers or tourists';

  @override
  String get shareThisCodeOnlyWhenYouAreOnBoard =>
      'Share this code only when you are on board';

  @override
  String get sharingLocation => 'SHARING LOCATION';

  @override
  String showValue(String value) {
    return 'Show $value';
  }

  @override
  String get signInAfterConfirmingYourEmail =>
      'Sign in after confirming your email.';

  @override
  String get signInBeforeSendingFeedback => 'Sign in before sending feedback.';

  @override
  String get signInFirst => 'Sign in first.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signUp => 'Sign up';

  @override
  String get skip => 'Skip';

  @override
  String
  get someInformationCouldNotRefreshPreviouslyLoadedDataIsShownReconnectAndRetry =>
      'Some information could not refresh. Previously loaded data is shown; reconnect and retry.';

  @override
  String get sos => 'SOS';

  @override
  String get spotName => 'Spot name';

  @override
  String get spots => 'spots';

  @override
  String get staleOnlineDrivers => 'Stale online drivers';

  @override
  String get startNewSearch => 'Start new search';

  @override
  String statusValue(String value) {
    return '$value status';
  }

  @override
  String get stillToPay => 'Still to pay';

  @override
  String get stop => 'Stop';

  @override
  String get stopAtASafePlaceFirstTheTripWillEndImmediatelyPaymentWill =>
      'Stop at a safe place first. The trip will end immediately. Payment will be held for admin review; neither party can demand the full fare automatically. Describe what happened (changed plans, breakdown, safety concern, closed venue, etc.).';

  @override
  String stopCustomTourValue(String value) {
    return '$value stop custom tour';
  }

  @override
  String get stops => 'stops';

  @override
  String get stopsIncluded => 'Stops included';

  @override
  String get stopSkipApprovalNeeded => 'Stop-skip approval needed';

  @override
  String
  get stopSomewhereSafeFirstYourCurrentGpsLocationAndExplanationWillBeRecorded =>
      'Stop somewhere safe first. Your current GPS location and explanation will be recorded. The tourist can wait or end the tour for payment review.';

  @override
  String stopsValue(String value) {
    return '$value stops';
  }

  @override
  String stopsValueLabel(String value, String secondValue) {
    return '$value stops • ₱$secondValue';
  }

  @override
  String get stopTemporarilyUnavailable => 'Stop temporarily unavailable';

  @override
  String stopValue(String value) {
    return 'Stop: $value';
  }

  @override
  String get storageIsUnavailableRetryStorageBeforeMakingChanges =>
      'Storage is unavailable. Retry storage before making changes.';

  @override
  String get storeUnavailable => 'Store unavailable';

  @override
  String get streetHouseNo => 'Street/House No.';

  @override
  String get streetNameBuildingHouseNo => 'Street Name, Building, House No.';

  @override
  String get submit => 'Submit';

  @override
  String get submitApplication => 'Submit application';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String get submitReview => 'Submit review';

  @override
  String get submittedDocuments => 'Submitted documents';

  @override
  String get sun => 'Sun';

  @override
  String get supportSettings => 'Support & settings';

  @override
  String get suspend => 'Suspend';

  @override
  String get suspendDriver => 'Suspend driver';

  @override
  String get suspended => 'Suspended';

  @override
  String get suspendTourist => 'Suspend tourist?';

  @override
  String get suspendTouristLabel => 'Suspend tourist';

  @override
  String suspendValue(String value) {
    return 'Suspend $value';
  }

  @override
  String get systemActionsAreUnavailableHere =>
      'System actions are unavailable here.';

  @override
  String get systemFeedback => 'System feedback';

  @override
  String get tapTheHeartOnAnyTouristSpotToKeepItHere =>
      'Tap the heart on any tourist spot to keep it here.';

  @override
  String get tellUsWhatToImprove => 'Tell us what to improve';

  @override
  String get temporarilyCloseAttraction => 'Temporarily close attraction';

  @override
  String get temporarilyClosed => 'TEMPORARILY CLOSED';

  @override
  String temporarilyClosedValue(String value) {
    return '$value temporarily closed';
  }

  @override
  String get thankYouForYourFeedback => 'Thank you for your feedback!';

  @override
  String
  get thatPickupCodeIsIncorrectOrTemporarilyLockedAfterRepeatedAttempts =>
      'That pickup code is incorrect or temporarily locked after repeated attempts.';

  @override
  String get theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests =>
      'The agreed tour fare is fixed; there is no surge pricing. Pending requests and driver cancellations are free. After a driver accepts, the tourist has a short grace period, then the published cancellation fee may apply. After pickup, end safely and an admin reviews the completed service and evidence. Entrance fees and personal purchases remain separate.';

  @override
  String get theAssignedDriverIsUnavailable =>
      'The assigned driver is unavailable.';

  @override
  String get theBookingWillEndWithoutACancellationChargeIfAnOnlinePaymentWas =>
      'The booking will end without a cancellation charge. If an online payment was already received, it will be marked for refund.';

  @override
  String
  get theCheckoutAddressCouldNotBeVerifiedRefreshThisBookingBeforePaying =>
      'The checkout address could not be verified. Refresh this booking before paying.';

  @override
  String
  get theDriverMovedAwayFromThePlannedRouteAndNavigationWasRecalculatedLive =>
      'The driver moved away from the planned route and navigation was recalculated. Live tracking remains active.';

  @override
  String get theDriverReportedAVehicleProblem =>
      'The driver reported a vehicle problem.';

  @override
  String get theDriverWillFollowTheSelectedPinConfirmThatItMatchesTheAddress =>
      'The driver will follow the selected pin. Confirm that it matches the address you entered.';

  @override
  String get theFinalChargeMustBeBetweenZeroAndTheAgreedFare =>
      'The final charge must be between zero and the agreed fare.';

  @override
  String get theFinalChargeMustBeSettledBeforeConfirmingCash =>
      'The final charge must be settled before confirming cash.';

  @override
  String get theFinancialRecordRequiresTheConfiguredServer =>
      'The financial record requires the configured server.';

  @override
  String get theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd =>
      'The GPS position is stale or invalid. Wait for a fresh signal and retry.';

  @override
  String get theInteractiveOperationsMapIsAvailableInTheMobileApp =>
      'The interactive operations map is available in the mobile app.';

  @override
  String
  get theOtherParticipantMustApproveIfApprovedFinalPaymentWillBeHeldFor =>
      'The other participant must approve. If approved, final payment will be held for a fair admin review because the delivered route changed.';

  @override
  String get theOwnerMustVerifyLocalAgencyNumbersBeforeEnablingCalls =>
      'The owner must verify local agency numbers before enabling calls.';

  @override
  String get thePickupPinIsOutsideTheServiceAreaChooseANearbyPickupPoint =>
      'The pickup pin is outside the service area. Choose a nearby pickup point.';

  @override
  String get thePickupPinIsOutsideTheServiceAreaChooseAnotherPickupPoint =>
      'The pickup pin is outside the service area. Choose another pickup point.';

  @override
  String get thePickupWaitingPeriodHasNotFinished =>
      'The pickup waiting period has not finished.';

  @override
  String get thePolicyChangedWhileYouWereEditingReopenThisPage =>
      'The policy changed while you were editing. Reopen this page.';

  @override
  String get thePriceChangedReviewTheUpdatedFareAndConfirmAgain =>
      'The price changed. Review the updated fare and confirm again.';

  @override
  String get thereAreNoRegisteredTouristsYet =>
      'There are no registered tourists yet.';

  @override
  String get thereIsNoOpenReviewOnThisBooking =>
      'There is no open review on this booking.';

  @override
  String get thereIsNoOutstandingAmountToConfirm =>
      'There is no outstanding amount to confirm.';

  @override
  String get theRideRequestIsNoLongerAvailable =>
      'The ride request is no longer available.';

  @override
  String get theServerIsNotConfiguredOnThisBuildAddTheSupabaseUrlAnd =>
      'The server is not configured on this build. Add the Supabase URL and publishable key, then rebuild the app.';

  @override
  String get theTouristMustConfirmAllBookedStopsUseEndTourEarlyForAn =>
      'The tourist must confirm all booked stops. Use End tour early for an incomplete route.';

  @override
  String thisAccountBelongsToThePortal(String role) {
    return 'This account belongs to the $role portal.';
  }

  @override
  String thisAccountBelongsToThePortalValue(String value) {
    return 'This account belongs to the $value portal.';
  }

  @override
  String get thisAccountCannotSignIn => 'This account cannot sign in.';

  @override
  String get thisAccountHasAnInvalidRole => 'This account has an invalid role.';

  @override
  String get thisAccountIsNotCurrentlyAllowedToSignIn =>
      'This account is not currently allowed to sign in.';

  @override
  String get thisAccountIsStillAwaitingAdministratorApproval =>
      'This account is still awaiting administrator approval.';

  @override
  String
  get thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd =>
      'This action could not be completed. Your existing records are preserved. Refresh and try again.';

  @override
  String get thisAttractionBelongsToATourPackageHideItInsteadOfDeletingIt =>
      'This attraction belongs to a tour package. Hide it instead of deleting it.';

  @override
  String get thisAttractionIsInAnActiveBookingHideItForNewTripsInstead =>
      'This attraction is in an active booking. Hide it for new trips instead.';

  @override
  String get thisAttractionIsNoLongerAvailable =>
      'This attraction is no longer available.';

  @override
  String get thisBookingBelongsToAnotherTourist =>
      'This booking belongs to another tourist.';

  @override
  String get thisBookingCouldNotBeFound => 'This booking could not be found.';

  @override
  String get thisBookingIsAlreadyUnderReviewAddYourStatementToTheCase =>
      'This booking is already under review. Add your statement to the case.';

  @override
  String get thisBookingIsAssignedToAnotherDriver =>
      'This booking is assigned to another driver.';

  @override
  String get thisBookingRequestIsNotReadyToRetry =>
      'This booking request is not ready to retry.';

  @override
  String get thisCancellationIsCurrentlyFreeGiveTheRealReasonSoTheEventCan =>
      'This cancellation is currently free. Give the real reason so the event can be audited.';

  @override
  String
  get thisCompletesTheRefundWorkflowForThePaymongoTestTransactionRecordsTheResult =>
      'This completes the refund workflow for the PayMongo test transaction, records the result, and notifies the tourist. Enter the reason for the refund.';

  @override
  String get thisDriverAccountIsStillAwaitingAdministratorApproval =>
      'This driver account is still awaiting administrator approval.';

  @override
  String get thisField => 'This field';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisOpensYourPhoneDialerConfirmTheNumberBeforeCalling =>
      'This opens your phone dialer. Confirm the number before calling.';

  @override
  String get thisOpensYourPhoneDialerWith911YouMustPressCallToContact =>
      'This opens your phone dialer with 911. You must press Call to contact emergency services.';

  @override
  String get thisPackageCannotBeBookedUntilAllStopsAreAvailable =>
      'This package cannot be booked until all stops are available.';

  @override
  String get thisPackageHasAFixedRouteTheStopsAreAlreadySelectedForYou =>
      'This package has a fixed route. The stops are already selected for you.';

  @override
  String get thisPackageHasNoPublishedPrice =>
      'This package has no published price.';

  @override
  String get thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne =>
      'This password-reset link is invalid or expired. Request a new one.';

  @override
  String get thisPickupPinIsOutsideTheServiceAreaMoveThePinCloserTo =>
      'This pickup pin is outside the service area. Move the pin closer to the service centre.';

  @override
  String
  get thisRemovesYourLoginProfileDetailsDocumentsAndAvatarsRetainedTripAndFinancial =>
      'This removes your login, profile details, documents and avatars. Retained trip and financial records are disconnected from your identity. Finish or cancel active bookings first. Type DELETE to confirm.';

  @override
  String get thisRequestAlreadyExistsRefreshYourTripsBeforeTryingAgain =>
      'This request already exists. Refresh your trips before trying again.';

  @override
  String get thisRequestIsNoLongerAvailable =>
      'This request is no longer available.';

  @override
  String get thisSendsTheExactAmountToPaymongoAndRecordsOnlyTheProviderResult =>
      'This sends the exact amount to PayMongo and records only the provider result. PayMongo currently limits actual refunds to live transactions, so a test-mode rejection will remain clearly marked as not refunded. Enter the decision reason.';

  @override
  String get thisTouristAccountCannotBookRightNowContactTheAdministrator =>
      'This tourist account cannot book right now. Contact the administrator.';

  @override
  String get thisTouristAccountIsCurrentlyUnavailable =>
      'This tourist account is currently unavailable.';

  @override
  String get thisTripCouldNotBeFoundOrHasBeenRemoved =>
      'This trip could not be found or has been removed.';

  @override
  String get thisTripHasAlreadyEnded => 'This trip has already ended.';

  @override
  String get thisTripIsNotInProgress => 'This trip is not in progress.';

  @override
  String get thisTripUsesANewerStatusUpdateTheAppOrContactSupportBefore =>
      'This trip uses a newer status. Update the app or contact support before making changes.';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisYear => 'This year';

  @override
  String threeLineSummary(String value, String secondValue, String thirdValue) {
    return '$value · $secondValue\n$thirdValue';
  }

  @override
  String get thu => 'Thu';

  @override
  String get tipsReminders => 'Tips & Reminders';

  @override
  String get title => 'Title';

  @override
  String get today => 'Today';

  @override
  String get totalBookings => 'Total bookings';

  @override
  String get totalFare => 'Total fare';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get tourEndedEarlyPaymentHeldForReview =>
      'Tour ended early; payment held for review';

  @override
  String get tourist => 'Tourist';

  @override
  String get touristAccountActivated => 'Tourist account activated';

  @override
  String get touristAccounts => 'Tourist accounts';

  @override
  String get touristAccountSuspended => 'Tourist account suspended';

  @override
  String get touristAndDriverPolicyTerms => 'Tourist and driver policy terms';

  @override
  String touristConfirmedStopValue(String value) {
    return 'Tourist confirmed stop $value.';
  }

  @override
  String get touristNoShowAfterVerifiedPickupWait =>
      'Tourist no-show after verified pickup wait.';

  @override
  String get touristReportedAsANoShowAfterTheVerifiedWaitingPeriodPublishedNo =>
      'Tourist reported as a no-show after the verified waiting period. Published no-show fee applied.';

  @override
  String get tourists => 'Tourists';

  @override
  String get touristsAndDrivers => 'Tourists and drivers';

  @override
  String get touristSpot => 'Tourist spot';

  @override
  String get touristSpotCreated => 'Tourist spot created';

  @override
  String get touristSpotIssue => 'Tourist spot issue';

  @override
  String get touristSpots => 'Tourist spots';

  @override
  String get touristSpotUpdated => 'Tourist spot updated';

  @override
  String touristVisibilityValue(String value) {
    return '$value tourist visibility';
  }

  @override
  String get tourPackage => 'Tour package';

  @override
  String get tourPackages => 'Tour packages';

  @override
  String get tourScheduled => 'Tour scheduled';

  @override
  String get tricycleBooking => 'Tricycle booking';

  @override
  String get trip => 'Trip';

  @override
  String get tripCompletedFixedFareDueCashNotYetConfirmed =>
      'Trip completed. Fixed fare due; cash not yet confirmed.';

  @override
  String get tripControls => 'Trip controls';

  @override
  String get tripHistory => 'Trip history';

  @override
  String get tripOngoing => 'Trip ongoing';

  @override
  String tripPausedOpenTripControlsToChooseWhetherToWaitOrEndSafelyValue(
    String value,
  ) {
    return 'Trip paused: $value. Open Trip controls to choose whether to wait or end safely.';
  }

  @override
  String get tripPausedVehicleProblem => 'Trip paused · vehicle problem';

  @override
  String get tripPayment => 'Trip & payment';

  @override
  String get trips => 'Trips';

  @override
  String tripsValue(String value) {
    return 'Trips: $value';
  }

  @override
  String get tripUpdates => 'Trip updates';

  @override
  String get tryAdjustingYourFiltersOrSearchTerm =>
      'Try adjusting your filters or search term.';

  @override
  String get tue => 'Tue';

  @override
  String get turnByTurnMappingIsAvailableInTheMobileApp =>
      'Turn-by-turn mapping is available in the mobile app.';

  @override
  String get turnOnGpsToShareYourLocation =>
      'Turn on GPS to share your location.';

  @override
  String get turnOnLocationServicesToUseYourCurrentPosition =>
      'Turn on Location Services to use your current position.';

  @override
  String twoPartDetails(String value, String secondValue) {
    return '$value • $secondValue';
  }

  @override
  String twoPartSummary(String value, String secondValue) {
    return '$value · $secondValue';
  }

  @override
  String get unableToCheckAppRequirements => 'Unable to check app requirements';

  @override
  String get unableToLoadThePrivacyNotice =>
      'Unable to load the privacy notice';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get underreview => 'underReview';

  @override
  String get underReview => 'Under review';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownApplicationEnvironment =>
      'Unknown application environment.';

  @override
  String get unknownUntilManuallyReopened =>
      'Unknown / until manually reopened';

  @override
  String get unpaid => 'unpaid';

  @override
  String get unsettledCash => 'Unsettled cash';

  @override
  String get unsupportedOfflineCommand => 'Unsupported offline command.';

  @override
  String updateAppBeforeContinuingToUseBookingAndPaymentServices(
    String brandName,
  ) {
    return 'Update $brandName before continuing to use booking and payment services.';
  }

  @override
  String get updateApplication => 'Update application';

  @override
  String updatedSAgoValue(String value) {
    return 'updated ${value}s ago';
  }

  @override
  String get updatePassword => 'Update password';

  @override
  String get updateRequired => 'Update required';

  @override
  String get updateYourDriverDetails => 'Update your driver details';

  @override
  String get updatingRoute => 'Updating route...';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get uploading => 'Uploading…';

  @override
  String uploadValue(String value) {
    return 'Upload $value';
  }

  @override
  String get useAtLeast8Characters => 'Use at least 8 characters';

  @override
  String get useAtLeastEightCharactersAvoidAPasswordYouUseOnAnotherService =>
      'Use at least eight characters. Avoid a password you use on another service.';

  @override
  String get useLettersSpacesHyphensApostrophesOrPeriodsInYourName =>
      'Use letters, spaces, hyphens, apostrophes or periods in your name';

  @override
  String get useMyCurrentLocation => 'Use my current location';

  @override
  String get useNow => 'Use now';

  @override
  String get useThisOnlyIfYouCannotCompleteThePickupTheTouristWillDecide =>
      'Use this only if you cannot complete the pickup. The tourist will decide whether to search for another verified driver or cancel free of charge. Explain what happened.';

  @override
  String get vehicleAndReliability => 'Vehicle and reliability';

  @override
  String get vehicleImageSelected => 'Vehicle image selected';

  @override
  String get vehicleInfo => 'Vehicle info';

  @override
  String get vehicleInspection => 'Vehicle inspection';

  @override
  String get vehicleInspectionExpiresOn => 'vehicle_inspection_expires_on';

  @override
  String vehicleInspectionValue(String value) {
    return 'Vehicle inspection: $value';
  }

  @override
  String get vehicleIsSafeResumeTrip => 'Vehicle is safe · resume trip';

  @override
  String get vehicleProblem => 'vehicle problem';

  @override
  String get vehicleProblemPauseTripSafely =>
      'Vehicle problem · pause trip safely';

  @override
  String get verificationStatus => 'Verification status';

  @override
  String get verified => 'VERIFIED';

  @override
  String verifiedAppDriver(String brandName) {
    return 'Verified $brandName driver';
  }

  @override
  String get verifiedNearThePickupPoint => 'Verified near the pickup point';

  @override
  String get verifiedPickupArrivalIsRequiredBeforeReportingANoShow =>
      'Verified pickup arrival is required before reporting a no-show.';

  @override
  String get verifiedTourist => 'Verified tourist';

  @override
  String get verifyLocalAgencyNumbers => 'Verify local agency numbers';

  @override
  String get verifyPickup => 'Verify pickup';

  @override
  String get verifyPickupCodeStart => 'Verify pickup code & start';

  @override
  String get viewActiveDriversOnTheMap => 'View active drivers on the map';

  @override
  String get viewAll => 'View all';

  @override
  String get viewAndManageTouristAccounts => 'View and manage tourist accounts';

  @override
  String get viewBookingRequests => 'View booking requests';

  @override
  String get viewDetails => 'View details';

  @override
  String get viewMap => 'View map';

  @override
  String get viewMyTrips => 'View my trips';

  @override
  String get viewScheduledBooking => 'View scheduled booking';

  @override
  String viewValue(String value) {
    return 'View $value';
  }

  @override
  String get visible => 'Visible';

  @override
  String get visibleToTourists => 'Visible to Tourists';

  @override
  String get waitForTheMobileMapToLoadBeforeConfirmingAnExactPickupPin =>
      'Wait for the mobile map to load before confirming an exact pickup pin.';

  @override
  String get waitForTheTouristToConfirmThisStop =>
      'Wait for the tourist to confirm this stop.';

  @override
  String get waitForThisDriver => 'Wait for this driver';

  @override
  String get waitingForADriverToAcceptYouCanLeaveThisPageAndResume =>
      'Waiting for a driver to accept. You can leave this page and resume from Trips.';

  @override
  String get waitingForAnApprovedDriverToAcceptYourRequest =>
      'Waiting for an approved driver to accept your request.';

  @override
  String get waitingForCashReturnConfirmation =>
      'Waiting for cash return confirmation';

  @override
  String get waitingForLiveLocation => 'Waiting for live location';

  @override
  String get waitingForTheOtherCashConfirmation =>
      'Waiting for the other cash confirmation';

  @override
  String get waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute =>
      'Waiting for the other participant. Navigation stays on the current route.';

  @override
  String get waitingForTheTouristSDecision =>
      'Waiting for the tourist’s decision.';

  @override
  String get waitingForTheTouristToChooseDoNotProceedToPickup =>
      'Waiting for the tourist to choose. Do not proceed to pickup.';

  @override
  String get waitingPeriodCompleted => 'Waiting period completed';

  @override
  String get waived => 'waived';

  @override
  String get wed => 'Wed';

  @override
  String get weHaveSentPasswordRecoveryInstructionsToYourEmail =>
      'We have sent password recovery instructions to your email.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get weLlSendNearbyBookingsYourWay =>
      'We’ll send nearby bookings your way.';

  @override
  String get weWillRemindYouAndStartMatching30MinutesBeforePickup =>
      'We will remind you and start matching 30 minutes before pickup.';

  @override
  String get whatDidYouLikeOrDislike => 'What did you like or dislike?';

  @override
  String get whatSIncluded => 'What\'s Included';

  @override
  String get whenYouGetNotificationsTheyWillAppearHere =>
      'When you get notifications, they will appear here.';

  @override
  String get whereWouldYouLikeToGo => 'Where would you like to go?';

  @override
  String willBeCompletedInThePaymongoTestEnvironmentValue(String value) {
    return '$value will be completed in the PayMongo test environment.';
  }

  @override
  String get youAlreadyHaveAnActiveBookingOpenTripsToContinueOrCancelIt =>
      'You already have an active booking. Open Trips to continue or cancel it.';

  @override
  String get youAreTogether => 'You are together';

  @override
  String get youChoseToWaitTheDriverMustConfirmTheVehicleIsSafeBefore =>
      'You chose to wait. The driver must confirm the vehicle is safe before navigation resumes.';

  @override
  String get yourAccount => 'Your account';

  @override
  String
  get yourAccountCannotPerformThisActionRefreshYourAccountOrContactSupport =>
      'Your account cannot perform this action. Refresh your account or contact support.';

  @override
  String
  get yourAccountCanUploadApplicationDocumentsAndCheckApprovalGoingOnlineAndAccepting =>
      'Your account can upload application documents and check approval. Going online and accepting trips require administrator approval.';

  @override
  String get yourAccreditationIsVerified => 'Your accreditation is verified';

  @override
  String get yourActivity => 'Your activity';

  @override
  String get yourAdministratorRoleDoesNotIncludeThisArea =>
      'Your administrator role does not include this area.';

  @override
  String get yourAssignedTouristCanSeeYourLiveLocation =>
      'Your assigned tourist can see your live location';

  @override
  String get yourCompletedRidesWillAppearHere =>
      'Your completed rides will appear here.';

  @override
  String get yourDocumentsAreUnderReview => 'Your documents are under review.';

  @override
  String get yourDriver => 'Your driver';

  @override
  String get youReOffline => 'You’re offline';

  @override
  String get youReReadyToRide => 'You’re ready to ride';

  @override
  String yourFeedbackHelpsKeepAppTrusted(String brandName) {
    return 'Your feedback helps keep $brandName trusted.';
  }

  @override
  String
  get yourFixedFareRouteAndPaymentRecordStayUnchangedThePreviousDriverIs =>
      'Your fixed fare, route, and payment record stay unchanged. The previous driver is released and a new 10-minute search begins.';

  @override
  String get yourGuideYourRideInBustos => 'Your Guide, Your Ride in Bustos';

  @override
  String get yourJourneyYourWay => 'Your Journey, Your Way';

  @override
  String get yourLocalJourneyStartsHere => 'Your local journey starts here';

  @override
  String get yourPreviousCodeWillStopWorkingShareTheNewCodeOnlyAfterBoarding =>
      'Your previous code will stop working. Share the new code only after boarding. You can request a new code once every five minutes.';

  @override
  String get yourRidesAndReceipts => 'Your rides and receipts';

  @override
  String
  get yourTourIsReservedDriverMatchingBegins30MinutesBeforePickupAndReminders =>
      'Your tour is reserved. Driver matching begins 30 minutes before pickup, and reminders will appear in Notifications.';

  @override
  String get yourTravel => 'Your travel';

  @override
  String youWillBeSentToPaymongoTestCheckoutPaymentIsConfirmedOnlyAfter(
    String brandName,
  ) {
    return 'You will be sent to PayMongo test checkout. Payment is confirmed only after the secure webhook reaches $brandName.';
  }

  @override
  String get useDeviceLanguage => 'Use device language';

  @override
  String get philippineTime => 'Philippine time';

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
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String hoursMinutesDuration(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String numberOfTrips(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips',
      one: '1 trip',
    );
    return '$_temp0';
  }

  @override
  String activeTripLocationTitle(String brandName) {
    return '$brandName trip location active';
  }

  @override
  String notificationUpdateTitle(String brandName) {
    return '$brandName update';
  }

  @override
  String fieldMustBeBetween(String field, int minimum, int maximum) {
    return '$field must be between $minimum and $maximum.';
  }

  @override
  String selectedDestinationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count destinations',
      one: '$count destination',
    );
    return '$_temp0';
  }

  @override
  String spotCount(int count) {
    return '$count spots';
  }

  @override
  String buildYourDayWithStops(int count) {
    return 'Build your day ($count stops)';
  }

  @override
  String cancellationWithReason(String result, String reason) {
    return '$result. Reason: $reason';
  }

  @override
  String cashConfirmation(String payment, String actor, String confirmation) {
    return '$payment confirmed by $actor; $confirmation.';
  }

  @override
  String get bothPartiesConfirmed => 'both parties confirmed';

  @override
  String get awaitingOtherParty => 'awaiting the other party';

  @override
  String get exportPending => 'Pending';

  @override
  String get exportFulfilled => 'Export ready';

  @override
  String get exportRejected => 'Request declined';

  @override
  String get administrator => 'Administrator';

  @override
  String get payment => 'Payment';

  @override
  String get signInDidNotComplete => 'Sign-in did not complete.';

  @override
  String get authResetConfigurationRequired =>
      'Password recovery is not configured for this build.';

  @override
  String get pickupRecoveryFailed =>
      'Pickup-code recovery could not be confirmed. Retry from your booking.';

  @override
  String get offlineReplayUnsafe => 'This action cannot be retried offline.';

  @override
  String selectedStopsCount(int count) {
    return '$count selected stops';
  }

  @override
  String cancellationGraceExpired(int minutes, int percent, String fee) {
    return 'The $minutes-minute grace period has ended. The published $percent% cancellation fee is $fee. Give the reason before confirming.';
  }

  @override
  String get arrivedAtPickup => 'I have arrived at pickup';

  @override
  String get requestPickupReplacement =>
      'I cannot make this pickup · request replacement';

  @override
  String get confirmReachedStop => 'Yes, we reached this stop';

  @override
  String get reviewFinalCharge => 'Review and decide final charge';

  @override
  String trackingMovementSubtitle(String distance, String target, int seconds) {
    return '$distance $target · updated ${seconds}s ago';
  }

  @override
  String complianceServiceArea(String name, String radius) {
    return 'Service area: $name ($radius km)';
  }

  @override
  String get goOnline => 'Go online';

  @override
  String get call => 'Call';

  @override
  String get sendMessage => 'Send a message';

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get downloadReport => 'Download report';

  @override
  String get markResolved => 'Mark resolved';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get savePlace => 'Save place';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get luggage => 'Luggage';

  @override
  String get assistance => 'Assistance';

  @override
  String get friendly => 'Friendly';

  @override
  String get punctual => 'Punctual';

  @override
  String get terrible => 'Terrible';

  @override
  String get bad => 'Bad';

  @override
  String get okay => 'Okay';

  @override
  String get good => 'Good';

  @override
  String get excellent => 'Excellent!';

  @override
  String get province => 'Province';

  @override
  String get municipality => 'Municipality';

  @override
  String get resorts => 'Resorts';

  @override
  String get events => 'Events';

  @override
  String get farmsNature => 'Farms and nature';

  @override
  String get foodCafes => 'Food and cafés';

  @override
  String get pickup => 'Pickup';

  @override
  String get tricycle => 'Tricycle';

  @override
  String get oneYearMembership => '1 yr';

  @override
  String get lastThirtyDays => '30 days';

  @override
  String get lastSevenDays => '7 days';

  @override
  String get newTouristRating => ' 5.0 (New)';

  @override
  String get exampleOperatingHours => '8:00 AM - 5:00 PM';

  @override
  String get onePassenger => '1 passenger';

  @override
  String get twoPassengers => '2 passengers';

  @override
  String get threePassengers => '3 passengers';

  @override
  String get removeSavedPlace => 'Remove saved place';

  @override
  String get togglePhotoControls => 'Show or hide photo controls';

  @override
  String get paymentCheckoutCreated => 'Checkout created';

  @override
  String get paymentProcessing => 'Payment processing';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentAwaitingConfirmation => 'Awaiting payment confirmation';

  @override
  String get paymentRefundDue => 'Refund due';

  @override
  String get paymentRefundProcessing => 'Refund processing';

  @override
  String get actorSystem => 'System';

  @override
  String get statusBusy => 'Busy';

  @override
  String get privacyNoticeTitle => 'Privacy notice';

  @override
  String get privacyWelcomeTitle => 'Your privacy comes first';

  @override
  String privacyWelcomeBody(String brandName) {
    return 'Before you continue, review how $brandName uses your information and choose your preferences.';
  }

  @override
  String get privacyAccountTitle => 'Account and trip details';

  @override
  String get privacyAccountBody =>
      'Your details help manage your account, match your ride and keep trip records.';

  @override
  String get privacyLocationTitle => 'Location when needed';

  @override
  String get privacyLocationBody =>
      'Location supports pickup and navigation. Background location is requested only for driver service.';

  @override
  String get privacyChoiceTitle => 'You stay in control';

  @override
  String get privacyChoiceBody =>
      'Crash diagnostics are optional. You can request your data or delete your account in your profile.';

  @override
  String get privacyFullNotice => 'Read the full notice';

  @override
  String get privacyDiagnosticsHelp =>
      'Optional. Turning this off does not affect sign-in or bookings.';

  @override
  String get privacyRequiredHelp =>
      'Accept the notice to continue. Diagnostics are your choice.';

  @override
  String get privacyLoadingLabel => 'Checking your privacy preferences';

  @override
  String privacyVersionLabel(String version) {
    return 'Notice version $version';
  }

  @override
  String get tickTheAgreementToBook =>
      'Tick the agreement above the button to book.';

  @override
  String get driverDocumentsBlockOnline =>
      'Your driver documents are missing, expired or not yet verified. Check your profile or contact the admin.';

  @override
  String get moveWithin150mOfPickup =>
      'Move within 150 metres of the pickup point and try again.';

  @override
  String get gpsAccuracyTooLow =>
      'Your GPS signal is too weak. Move to an open area and try again.';
}
