import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fil'),
  ];

  /// No description provided for @serverConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'This action needs a connection to the server. Check your internet and sign in again.'**
  String get serverConnectionRequired;

  /// No description provided for @adminGcashDisputesOpen.
  ///
  /// In en, this message translates to:
  /// **'{count} disputed GCash fares'**
  String adminGcashDisputesOpen(int count);

  /// No description provided for @outstandingFareBlocked.
  ///
  /// In en, this message translates to:
  /// **'You have an unpaid fare from an earlier trip. Pay your driver, or ask support, before booking again.'**
  String get outstandingFareBlocked;

  /// No description provided for @outstandingFareTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpaid fare'**
  String get outstandingFareTitle;

  /// No description provided for @outstandingFareAction.
  ///
  /// In en, this message translates to:
  /// **'Open unpaid trip'**
  String get outstandingFareAction;

  /// No description provided for @gcashReferenceUsed.
  ///
  /// In en, this message translates to:
  /// **'This GCash reference number was already used for another trip.'**
  String get gcashReferenceUsed;

  /// No description provided for @gcashProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Your driver reported the payment as not received. Send your receipt and reference number instead.'**
  String get gcashProofRequired;

  /// No description provided for @onlinePaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Online card payment is no longer available. Choose cash or GCash.'**
  String get onlinePaymentUnavailable;

  /// No description provided for @gcashQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s GCash QR'**
  String get gcashQrTitle;

  /// No description provided for @gcashSaveQr.
  ///
  /// In en, this message translates to:
  /// **'Share or save QR'**
  String get gcashSaveQr;

  /// No description provided for @gcashQrHint.
  ///
  /// In en, this message translates to:
  /// **'In GCash, tap Scan QR, then Upload QR, and choose this image. You can also scan the QR on the tricycle.'**
  String get gcashQrHint;

  /// No description provided for @gcashQrMissing.
  ///
  /// In en, this message translates to:
  /// **'This driver hasn\'t uploaded a QR code. Use the number below.'**
  String get gcashQrMissing;

  /// No description provided for @gcashUploadQr.
  ///
  /// In en, this message translates to:
  /// **'Upload GCash QR'**
  String get gcashUploadQr;

  /// No description provided for @gcashReplaceQr.
  ///
  /// In en, this message translates to:
  /// **'Replace QR'**
  String get gcashReplaceQr;

  /// No description provided for @gcashQrSaved.
  ///
  /// In en, this message translates to:
  /// **'QR code saved'**
  String get gcashQrSaved;

  /// No description provided for @gcashQrDescription.
  ///
  /// In en, this message translates to:
  /// **'Tourists see your QR only when paying you for a completed trip.'**
  String get gcashQrDescription;

  /// No description provided for @gcashProofTitle.
  ///
  /// In en, this message translates to:
  /// **'Send payment proof'**
  String get gcashProofTitle;

  /// No description provided for @gcashProofBody.
  ///
  /// In en, this message translates to:
  /// **'Your driver hasn\'t received the payment yet. Attach your GCash receipt screenshot and the reference number.'**
  String get gcashProofBody;

  /// No description provided for @gcashChooseReceipt.
  ///
  /// In en, this message translates to:
  /// **'Choose receipt screenshot'**
  String get gcashChooseReceipt;

  /// No description provided for @gcashReceiptChosen.
  ///
  /// In en, this message translates to:
  /// **'Receipt selected'**
  String get gcashReceiptChosen;

  /// No description provided for @gcashReferenceRequired.
  ///
  /// In en, this message translates to:
  /// **'GCash reference number'**
  String get gcashReferenceRequired;

  /// No description provided for @gcashSubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Send proof'**
  String get gcashSubmitProof;

  /// No description provided for @gcashProofSent.
  ///
  /// In en, this message translates to:
  /// **'Proof sent to your driver'**
  String get gcashProofSent;

  /// No description provided for @gcashViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get gcashViewReceipt;

  /// No description provided for @gcashAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ask admin to decide'**
  String get gcashAskAdmin;

  /// No description provided for @gcashAskAdminBody.
  ///
  /// In en, this message translates to:
  /// **'Use this only if you can\'t settle it together. An admin will check the receipt and decide.'**
  String get gcashAskAdminBody;

  /// No description provided for @gcashAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the admin (optional)'**
  String get gcashAdminNote;

  /// No description provided for @gcashSentToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sent to admin review'**
  String get gcashSentToAdmin;

  /// No description provided for @gcashEscalatedNotice.
  ///
  /// In en, this message translates to:
  /// **'An admin is reviewing this payment. You can still settle it together.'**
  String get gcashEscalatedNotice;

  /// No description provided for @gcashRulingPaid.
  ///
  /// In en, this message translates to:
  /// **'Admin decision: paid'**
  String get gcashRulingPaid;

  /// No description provided for @gcashRulingNotPaid.
  ///
  /// In en, this message translates to:
  /// **'Admin decision: not paid'**
  String get gcashRulingNotPaid;

  /// No description provided for @gcashRulingWaived.
  ///
  /// In en, this message translates to:
  /// **'Admin decision: fare waived'**
  String get gcashRulingWaived;

  /// No description provided for @gcashReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'GCash reference'**
  String get gcashReferenceLabel;

  /// No description provided for @adminGcashDisputes.
  ///
  /// In en, this message translates to:
  /// **'GCash disputes'**
  String get adminGcashDisputes;

  /// No description provided for @adminGcashDisputesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open GCash disputes.'**
  String get adminGcashDisputesEmpty;

  /// No description provided for @adminDisputeEscalated.
  ///
  /// In en, this message translates to:
  /// **'Needs a decision'**
  String get adminDisputeEscalated;

  /// No description provided for @adminDisputeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for tourist and driver'**
  String get adminDisputeWaiting;

  /// No description provided for @adminDisputeUnsettled.
  ///
  /// In en, this message translates to:
  /// **'Ruled not paid · unsettled'**
  String get adminDisputeUnsettled;

  /// No description provided for @adminRulePaid.
  ///
  /// In en, this message translates to:
  /// **'Decide: tourist paid'**
  String get adminRulePaid;

  /// No description provided for @adminRuleNotPaid.
  ///
  /// In en, this message translates to:
  /// **'Decide: tourist didn\'t pay'**
  String get adminRuleNotPaid;

  /// No description provided for @adminWaiveFare.
  ///
  /// In en, this message translates to:
  /// **'Waive fare'**
  String get adminWaiveFare;

  /// No description provided for @adminRulingReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for your decision'**
  String get adminRulingReason;

  /// No description provided for @adminNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'No receipt submitted yet.'**
  String get adminNoReceipt;

  /// No description provided for @adminDriverNote.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s note'**
  String get adminDriverNote;

  /// No description provided for @adminEscalationNote.
  ///
  /// In en, this message translates to:
  /// **'Escalation note'**
  String get adminEscalationNote;

  /// No description provided for @adminDecisionSaved.
  ///
  /// In en, this message translates to:
  /// **'Decision saved'**
  String get adminDecisionSaved;

  /// No description provided for @gcashSendToDriver.
  ///
  /// In en, this message translates to:
  /// **'GCash (send to driver)'**
  String get gcashSendToDriver;

  /// No description provided for @gcashAfterTrip.
  ///
  /// In en, this message translates to:
  /// **'You\'ll send the fare to your driver\'s GCash after the trip.'**
  String get gcashAfterTrip;

  /// No description provided for @gcashCompleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Complete trip'**
  String get gcashCompleteTrip;

  /// No description provided for @gcashDetails.
  ///
  /// In en, this message translates to:
  /// **'GCash payment details'**
  String get gcashDetails;

  /// No description provided for @gcashNumber.
  ///
  /// In en, this message translates to:
  /// **'GCash number'**
  String get gcashNumber;

  /// No description provided for @gcashConfirmNumber.
  ///
  /// In en, this message translates to:
  /// **'Re-enter GCash number'**
  String get gcashConfirmNumber;

  /// No description provided for @gcashAccountName.
  ///
  /// In en, this message translates to:
  /// **'Registered GCash account name'**
  String get gcashAccountName;

  /// No description provided for @gcashActive.
  ///
  /// In en, this message translates to:
  /// **'Accept GCash payments'**
  String get gcashActive;

  /// No description provided for @gcashInactive.
  ///
  /// In en, this message translates to:
  /// **'GCash payments disabled'**
  String get gcashInactive;

  /// No description provided for @gcashNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'This driver has not added GCash details.'**
  String get gcashNotConfigured;

  /// No description provided for @gcashVisibility.
  ///
  /// In en, this message translates to:
  /// **'Tourists will see this number and name when paying you by GCash.'**
  String get gcashVisibility;

  /// No description provided for @gcashInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number in 09XXXXXXXXX or +639XXXXXXXXX format.'**
  String get gcashInvalidNumber;

  /// No description provided for @gcashNumberMismatch.
  ///
  /// In en, this message translates to:
  /// **'The GCash numbers must match.'**
  String get gcashNumberMismatch;

  /// No description provided for @gcashInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter the account name using 2 to 120 characters.'**
  String get gcashInvalidName;

  /// No description provided for @gcashCheckName.
  ///
  /// In en, this message translates to:
  /// **'Before sending, check that the name shown in GCash matches this account name.'**
  String get gcashCheckName;

  /// No description provided for @gcashOpen.
  ///
  /// In en, this message translates to:
  /// **'Open GCash'**
  String get gcashOpen;

  /// No description provided for @gcashLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'GCash isn\'t installed or couldn\'t be opened. You can still copy the number and amount.'**
  String get gcashLaunchFailed;

  /// No description provided for @gcashCopyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get gcashCopyNumber;

  /// No description provided for @gcashCopyAmount.
  ///
  /// In en, this message translates to:
  /// **'Copy amount'**
  String get gcashCopyAmount;

  /// No description provided for @gcashNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get gcashNumberCopied;

  /// No description provided for @gcashAmountCopied.
  ///
  /// In en, this message translates to:
  /// **'Amount copied'**
  String get gcashAmountCopied;

  /// No description provided for @gcashSent.
  ///
  /// In en, this message translates to:
  /// **'I\'ve sent the payment'**
  String get gcashSent;

  /// No description provided for @gcashReference.
  ///
  /// In en, this message translates to:
  /// **'GCash reference number (optional)'**
  String get gcashReference;

  /// No description provided for @gcashInvalidReference.
  ///
  /// In en, this message translates to:
  /// **'Use 8 to 20 letters or digits for the reference number.'**
  String get gcashInvalidReference;

  /// No description provided for @gcashPayCash.
  ///
  /// In en, this message translates to:
  /// **'Pay with cash instead'**
  String get gcashPayCash;

  /// No description provided for @gcashNotSetUp.
  ///
  /// In en, this message translates to:
  /// **'Your driver hasn\'t set up GCash. Please pay with cash.'**
  String get gcashNotSetUp;

  /// No description provided for @gcashAwaitingDriver.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver confirmation'**
  String get gcashAwaitingDriver;

  /// No description provided for @gcashAwaitingYour.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your confirmation'**
  String get gcashAwaitingYour;

  /// No description provided for @gcashDisputed.
  ///
  /// In en, this message translates to:
  /// **'GCash payment disputed'**
  String get gcashDisputed;

  /// No description provided for @gcashDisputeMessage.
  ///
  /// In en, this message translates to:
  /// **'Your driver hasn\'t received the payment yet. Check your GCash receipt and reference number, or pay in cash.'**
  String get gcashDisputeMessage;

  /// No description provided for @gcashSlide.
  ///
  /// In en, this message translates to:
  /// **'Slide to confirm payment received'**
  String get gcashSlide;

  /// No description provided for @gcashDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment received'**
  String get gcashDriverConfirm;

  /// No description provided for @gcashNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received yet'**
  String get gcashNotReceived;

  /// No description provided for @gcashDisputeNote.
  ///
  /// In en, this message translates to:
  /// **'Short note (optional)'**
  String get gcashDisputeNote;

  /// No description provided for @gcashPaidByDriver.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed by driver'**
  String get gcashPaidByDriver;

  /// No description provided for @gcashActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this GCash action. Refresh the booking and try again.'**
  String get gcashActionFailed;

  /// No description provided for @gcashSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'GCash details saved'**
  String get gcashSettingsSaved;

  /// No description provided for @gcashCashWarning.
  ///
  /// In en, this message translates to:
  /// **'If you already sent money, check your GCash receipt with the driver before paying in cash.'**
  String get gcashCashWarning;

  /// No description provided for @gcashFareToPay.
  ///
  /// In en, this message translates to:
  /// **'Fare to pay'**
  String get gcashFareToPay;

  /// No description provided for @gcashCheckWallet.
  ///
  /// In en, this message translates to:
  /// **'Check that the fare arrived in your GCash before confirming.'**
  String get gcashCheckWallet;

  /// No description provided for @gcashAmountReceived.
  ///
  /// In en, this message translates to:
  /// **'GCash fare received'**
  String get gcashAmountReceived;

  /// No description provided for @gcashConfirmedFares.
  ///
  /// In en, this message translates to:
  /// **'Confirmed fares'**
  String get gcashConfirmedFares;

  /// No description provided for @gcashConfirmedFaresOverTime.
  ///
  /// In en, this message translates to:
  /// **'Confirmed fares over time'**
  String get gcashConfirmedFaresOverTime;

  /// No description provided for @loadedBookingTotals.
  ///
  /// In en, this message translates to:
  /// **'These figures cover only bookings loaded in the app.'**
  String get loadedBookingTotals;

  /// No description provided for @gcashEarningsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Includes confirmed direct GCash fares. Amounts under review are excluded.'**
  String get gcashEarningsExplanation;

  /// No description provided for @abc1234.
  ///
  /// In en, this message translates to:
  /// **'ABC 1234'**
  String get abc1234;

  /// No description provided for @abc1234AccreditedDriver.
  ///
  /// In en, this message translates to:
  /// **'ABC 1234 • Accredited driver'**
  String get abc1234AccreditedDriver;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @acceptAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get acceptAndContinue;

  /// No description provided for @acceptAssistanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Accept assistance requests'**
  String get acceptAssistanceRequests;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @acceptTheCurrentPrivacyNoticeBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Accept the current privacy notice before submitting.'**
  String get acceptTheCurrentPrivacyNoticeBeforeSubmitting;

  /// No description provided for @accessibilityOrAssistanceNeeds.
  ///
  /// In en, this message translates to:
  /// **'Accessibility or assistance needs'**
  String get accessibilityOrAssistanceNeeds;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Account access could not be completed. Check your details and try again.'**
  String get accountAccessCouldNotBeCompletedCheckYourDetailsAndTryAgain;

  /// No description provided for @accountCreatedConfirmYourEmailThenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Account created. Confirm your email, then sign in.'**
  String get accountCreatedConfirmYourEmailThenSignIn;

  /// No description provided for @accreditationVerified.
  ///
  /// In en, this message translates to:
  /// **'Accreditation verified'**
  String get accreditationVerified;

  /// No description provided for @aConfiguredServerAndAdministratorAccountAreRequired.
  ///
  /// In en, this message translates to:
  /// **'A configured server and administrator account are required.'**
  String get aConfiguredServerAndAdministratorAccountAreRequired;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @activateTourist.
  ///
  /// In en, this message translates to:
  /// **'Activate tourist'**
  String get activateTourist;

  /// Application message: activateValue
  ///
  /// In en, this message translates to:
  /// **'Activate {value}'**
  String activateValue(String value);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active trip'**
  String get activeTrip;

  /// No description provided for @activeTripRoute.
  ///
  /// In en, this message translates to:
  /// **'Active trip route'**
  String get activeTripRoute;

  /// No description provided for @actNow.
  ///
  /// In en, this message translates to:
  /// **'Act now'**
  String get actNow;

  /// No description provided for @addAStatementToThisCase.
  ///
  /// In en, this message translates to:
  /// **'Add a statement to this case'**
  String get addAStatementToThisCase;

  /// No description provided for @addedToItinerary.
  ///
  /// In en, this message translates to:
  /// **'Added to itinerary!'**
  String get addedToItinerary;

  /// No description provided for @addedToYourItinerary.
  ///
  /// In en, this message translates to:
  /// **'Added to your itinerary!'**
  String get addedToYourItinerary;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address details'**
  String get addressDetails;

  /// No description provided for @addressMatchesPin.
  ///
  /// In en, this message translates to:
  /// **'Address matches pin'**
  String get addressMatchesPin;

  /// No description provided for @addToTrip.
  ///
  /// In en, this message translates to:
  /// **'+ Add to trip'**
  String get addToTrip;

  /// No description provided for @addToTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to trip'**
  String get addToTripLabel;

  /// No description provided for @addTouristSpot.
  ///
  /// In en, this message translates to:
  /// **'Add tourist spot'**
  String get addTouristSpot;

  /// No description provided for @addYourStatement.
  ///
  /// In en, this message translates to:
  /// **'Add your statement'**
  String get addYourStatement;

  /// No description provided for @aDestinationIsNoLongerAvailableUpdateYourItinerary.
  ///
  /// In en, this message translates to:
  /// **'A destination is no longer available. Update your itinerary.'**
  String get aDestinationIsNoLongerAvailableUpdateYourItinerary;

  /// No description provided for @adjustPin.
  ///
  /// In en, this message translates to:
  /// **'Adjust pin'**
  String get adjustPin;

  /// No description provided for @administratorUpdatedFixedFares.
  ///
  /// In en, this message translates to:
  /// **'Administrator updated fixed fares.'**
  String get administratorUpdatedFixedFares;

  /// No description provided for @adminPasswordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin password is required'**
  String get adminPasswordIsRequired;

  /// No description provided for @adminReviewPaymentOnHold.
  ///
  /// In en, this message translates to:
  /// **'Admin review · payment on hold'**
  String get adminReviewPaymentOnHold;

  /// No description provided for @affectedTouristsAndAssignedDriversWillBeNotifiedExistingBookingsKeepAnAudit.
  ///
  /// In en, this message translates to:
  /// **'Affected tourists and assigned drivers will be notified. Existing bookings keep an audit record.'**
  String
  get affectedTouristsAndAssignedDriversWillBeNotifiedExistingBookingsKeepAnAudit;

  /// No description provided for @agreeAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get agreeAndContinue;

  /// No description provided for @agreedFare.
  ///
  /// In en, this message translates to:
  /// **'Agreed fare'**
  String get agreedFare;

  /// No description provided for @agreedFixedFare.
  ///
  /// In en, this message translates to:
  /// **'Agreed fixed fare'**
  String get agreedFixedFare;

  /// Application message: agreedMaximumStopsConfirmedByTheTouristTheSuggestedProratedAmountIsAValue
  ///
  /// In en, this message translates to:
  /// **'Agreed maximum: {value}. {secondValue}/{thirdValue} stops confirmed by the tourist. The suggested prorated amount is a starting point only. Review both statements, safety concerns and service delivered. No penalties or extras.'**
  String
  agreedMaximumStopsConfirmedByTheTouristTheSuggestedProratedAmountIsAValue(
    String value,
    String secondValue,
    String thirdValue,
  );

  /// No description provided for @agreedPolicy.
  ///
  /// In en, this message translates to:
  /// **'Agreed policy'**
  String get agreedPolicy;

  /// Application message: agreedValue
  ///
  /// In en, this message translates to:
  /// **'Agreed\n₱{value}'**
  String agreedValue(String value);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allowLocationAccessInAndroidSettings.
  ///
  /// In en, this message translates to:
  /// **'Allow location access in Android settings.'**
  String get allowLocationAccessInAndroidSettings;

  /// No description provided for @allowMatchingForTouristsWithMobilityOrBoardingNeeds.
  ///
  /// In en, this message translates to:
  /// **'Allow matching for tourists with mobility or boarding needs.'**
  String get allowMatchingForTouristsWithMobilityOrBoardingNeeds;

  /// No description provided for @allowOptionalCrashDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Allow optional crash diagnostics'**
  String get allowOptionalCrashDiagnostics;

  /// No description provided for @allStopsAreConfirmedOpenTripControlsToFinish.
  ///
  /// In en, this message translates to:
  /// **'All stops are confirmed. Open Trip controls to finish.'**
  String get allStopsAreConfirmedOpenTripControlsToFinish;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @aNearbyTouristIsLookingForADriver.
  ///
  /// In en, this message translates to:
  /// **'A nearby tourist is looking for a driver.'**
  String get aNearbyTouristIsLookingForADriver;

  /// No description provided for @announcementSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Announcement sent successfully'**
  String get announcementSentSuccessfully;

  /// No description provided for @anotherAccountIsAlreadySignedInSignOutBeforeRegisteringADriver.
  ///
  /// In en, this message translates to:
  /// **'Another account is already signed in. Sign out before registering a driver.'**
  String get anotherAccountIsAlreadySignedInSignOutBeforeRegisteringADriver;

  /// No description provided for @aPackageStopIsUnavailablePleaseChooseAnotherRoute.
  ///
  /// In en, this message translates to:
  /// **'A package stop is unavailable. Please choose another route.'**
  String get aPackageStopIsUnavailablePleaseChooseAnotherRoute;

  /// Application message: appDriverIsOnline
  ///
  /// In en, this message translates to:
  /// **'{brandName} driver is online'**
  String appDriverIsOnline(String brandName);

  /// No description provided for @applicationPending.
  ///
  /// In en, this message translates to:
  /// **'Application pending'**
  String get applicationPending;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected.'**
  String get applicationRejected;

  /// No description provided for @applicationSubmittedForAdministratorReview.
  ///
  /// In en, this message translates to:
  /// **'Application submitted for administrator review.'**
  String get applicationSubmittedForAdministratorReview;

  /// Application message: appManagementSystem
  ///
  /// In en, this message translates to:
  /// **'{brandName} Management System'**
  String appManagementSystem(String brandName);

  /// Application message: appName
  ///
  /// In en, this message translates to:
  /// **'{brandName}'**
  String appName(String brandName);

  /// Application message: appReportValue
  ///
  /// In en, this message translates to:
  /// **'{brandName} {value} report'**
  String appReportValue(String value, String brandName);

  /// No description provided for @approveAndEnableMatching.
  ///
  /// In en, this message translates to:
  /// **'Approve and enable matching'**
  String get approveAndEnableMatching;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @approvedServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Approved service area'**
  String get approvedServiceArea;

  /// No description provided for @approveRouteChange.
  ///
  /// In en, this message translates to:
  /// **'Approve route change'**
  String get approveRouteChange;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @aPrePickupReviewCannotIncreaseTheSnapshottedCancellationCharge.
  ///
  /// In en, this message translates to:
  /// **'A pre-pickup review cannot increase the snapshotted cancellation charge.'**
  String get aPrePickupReviewCannotIncreaseTheSnapshottedCancellationCharge;

  /// No description provided for @aPreviousBookingRequestIsAwaitingConfirmationReconnectAndOpenTripsBeforeChanging.
  ///
  /// In en, this message translates to:
  /// **'A previous booking request is awaiting confirmation. Reconnect and open Trips before changing the request.'**
  String
  get aPreviousBookingRequestIsAwaitingConfirmationReconnectAndOpenTripsBeforeChanging;

  /// No description provided for @areaName.
  ///
  /// In en, this message translates to:
  /// **'Area name'**
  String get areaName;

  /// No description provided for @areaUnverified.
  ///
  /// In en, this message translates to:
  /// **'Area unverified'**
  String get areaUnverified;

  /// Application message: areCurrentlyOnATripValue
  ///
  /// In en, this message translates to:
  /// **'{value} are currently on a trip'**
  String areCurrentlyOnATripValue(String value);

  /// No description provided for @areYouInAnEmergency.
  ///
  /// In en, this message translates to:
  /// **'Are you in an emergency?'**
  String get areYouInAnEmergency;

  /// No description provided for @areYouSureYouWantToLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogOut;

  /// Application message: areYouSureYouWantToLogOutOfApp
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of {brandName}?'**
  String areYouSureYouWantToLogOutOfApp(String brandName);

  /// Application message: arrivalReportedValue
  ///
  /// In en, this message translates to:
  /// **'Arrival reported: {value}.'**
  String arrivalReportedValue(String value);

  /// No description provided for @askTheTouristForTheCorrectPickupCodeOnceTheyAreOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Ask the tourist for the correct pickup code once they are on board.'**
  String get askTheTouristForTheCorrectPickupCodeOnceTheyAreOnBoard;

  /// No description provided for @askTheTouristForTheirCodeAfterTheyAreSafelyOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Ask the tourist for their code after they are safely on board.'**
  String get askTheTouristForTheirCodeAfterTheyAreSafelyOnBoard;

  /// No description provided for @assignedDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get assignedDriver;

  /// No description provided for @attachBothRequiredDriverDocuments.
  ///
  /// In en, this message translates to:
  /// **'Attach both required driver documents.'**
  String get attachBothRequiredDriverDocuments;

  /// Application message: attachedValue
  ///
  /// In en, this message translates to:
  /// **'{value} attached'**
  String attachedValue(String value);

  /// No description provided for @attraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get attraction;

  /// Application message: attractionAndFareInformationIsSynchronizedWithApp
  ///
  /// In en, this message translates to:
  /// **'Attraction and fare information is synchronized with {brandName}.'**
  String attractionAndFareInformationIsSynchronizedWithApp(String brandName);

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// Application message: audienceValue
  ///
  /// In en, this message translates to:
  /// **'Audience: {value}'**
  String audienceValue(String value);

  /// No description provided for @auditedRouteChangesRequireTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'Audited route changes require the configured server.'**
  String get auditedRouteChangesRequireTheConfiguredServer;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Application message: avatarCleanupPendingForObjectValue
  ///
  /// In en, this message translates to:
  /// **'Avatar cleanup pending for object {value}'**
  String avatarCleanupPendingForObjectValue(String value);

  /// No description provided for @avatarObjectVersionIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Avatar object version is invalid.'**
  String get avatarObjectVersionIsInvalid;

  /// No description provided for @avatarOwnerIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Avatar owner is invalid.'**
  String get avatarOwnerIsInvalid;

  /// No description provided for @awaitingBothCashConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Awaiting both cash confirmations'**
  String get awaitingBothCashConfirmations;

  /// Application message: awaitingPaymentValue
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment: ₱{value}'**
  String awaitingPaymentValue(String value);

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToExplore.
  ///
  /// In en, this message translates to:
  /// **'Back to explore'**
  String get backToExplore;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToLogin;

  /// No description provided for @barangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get barangay;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @blockedCheckoutExpiry.
  ///
  /// In en, this message translates to:
  /// **'Blocked checkout expiry'**
  String get blockedCheckoutExpiry;

  /// No description provided for @bongaMayor.
  ///
  /// In en, this message translates to:
  /// **'Bonga mayor'**
  String get bongaMayor;

  /// No description provided for @bongaMenor.
  ///
  /// In en, this message translates to:
  /// **'Bonga menor'**
  String get bongaMenor;

  /// No description provided for @bookATourToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Book a tour to get started!'**
  String get bookATourToGetStarted;

  /// No description provided for @bookATricycle.
  ///
  /// In en, this message translates to:
  /// **'Book a tricycle'**
  String get bookATricycle;

  /// Application message: bookForValue
  ///
  /// In en, this message translates to:
  /// **'Book for ₱{value}'**
  String bookForValue(String value);

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @bookingAndSystemUpdates.
  ///
  /// In en, this message translates to:
  /// **'Booking and system updates'**
  String get bookingAndSystemUpdates;

  /// No description provided for @bookingDetailsCancel.
  ///
  /// In en, this message translates to:
  /// **'Booking details / cancel'**
  String get bookingDetailsCancel;

  /// No description provided for @bookingDriverPaymentAndSafetyUpdates.
  ///
  /// In en, this message translates to:
  /// **'Booking, driver, payment, and safety updates'**
  String get bookingDriverPaymentAndSafetyUpdates;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking history'**
  String get bookingHistory;

  /// No description provided for @bookingNotFoundForThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Booking not found for this account.'**
  String get bookingNotFoundForThisAccount;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @bookingSessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Booking session changed.'**
  String get bookingSessionChanged;

  /// No description provided for @bookingsPaymentReviews.
  ///
  /// In en, this message translates to:
  /// **'Bookings & payment reviews'**
  String get bookingsPaymentReviews;

  /// No description provided for @bookingsToday.
  ///
  /// In en, this message translates to:
  /// **'Bookings today'**
  String get bookingsToday;

  /// Application message: bookingValue
  ///
  /// In en, this message translates to:
  /// **'Booking {value}'**
  String bookingValue(String value);

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @bookThisTour.
  ///
  /// In en, this message translates to:
  /// **'Book this tour'**
  String get bookThisTour;

  /// No description provided for @bothDriverDocumentsAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Both driver documents are required.'**
  String get bothDriverDocumentsAreRequired;

  /// No description provided for @bothDriverDocumentsMustBeValidImagesUnder5Mb.
  ///
  /// In en, this message translates to:
  /// **'Both driver documents must be valid images under 5 MB.'**
  String get bothDriverDocumentsMustBeValidImagesUnder5Mb;

  /// No description provided for @brandMark.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get brandMark;

  /// No description provided for @broadcastAMessage.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a message'**
  String get broadcastAMessage;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get bugReport;

  /// No description provided for @buildADayYouLlRemember.
  ///
  /// In en, this message translates to:
  /// **'Build a day you\'ll remember'**
  String get buildADayYouLlRemember;

  /// No description provided for @buildYourDay.
  ///
  /// In en, this message translates to:
  /// **'Build your day'**
  String get buildYourDay;

  /// No description provided for @buildYourItineraryAndEnjoyAPersonalizedTourExperience.
  ///
  /// In en, this message translates to:
  /// **'Build your itinerary and enjoy a personalized tour experience.'**
  String get buildYourItineraryAndEnjoyAPersonalizedTourExperience;

  /// No description provided for @buildYourOwnDay.
  ///
  /// In en, this message translates to:
  /// **'Build your own day'**
  String get buildYourOwnDay;

  /// Application message: bulletItem
  ///
  /// In en, this message translates to:
  /// **'• {value}'**
  String bulletItem(String value);

  /// No description provided for @bustosBulacan.
  ///
  /// In en, this message translates to:
  /// **'Bustos, Bulacan'**
  String get bustosBulacan;

  /// No description provided for @bustosTourMap.
  ///
  /// In en, this message translates to:
  /// **'Bustos tour map'**
  String get bustosTourMap;

  /// No description provided for @bustosTownCentre.
  ///
  /// In en, this message translates to:
  /// **'Bustos town centre'**
  String get bustosTownCentre;

  /// No description provided for @calculatingLocalRoadRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating local-road route...'**
  String get calculatingLocalRoadRoute;

  /// No description provided for @callEmergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Call emergency services?'**
  String get callEmergencyServices;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get cancelBooking;

  /// Application message: cancelBookingFeeValue
  ///
  /// In en, this message translates to:
  /// **'Cancel booking ({value}% fee)'**
  String cancelBookingFeeValue(String value);

  /// No description provided for @cancelBookingNoCharge.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking (no charge)'**
  String get cancelBookingNoCharge;

  /// No description provided for @cancelFree.
  ///
  /// In en, this message translates to:
  /// **'Cancel free'**
  String get cancelFree;

  /// No description provided for @cancelFreeOfCharge.
  ///
  /// In en, this message translates to:
  /// **'Cancel free of charge'**
  String get cancelFreeOfCharge;

  /// No description provided for @cancellationAndPaymentPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation and payment policy'**
  String get cancellationAndPaymentPolicy;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancelledAfterTheGracePeriodPublishedCancellationFeeApplied.
  ///
  /// In en, this message translates to:
  /// **'Cancelled after the grace period; published cancellation fee applied'**
  String get cancelledAfterTheGracePeriodPublishedCancellationFeeApplied;

  /// No description provided for @cancelledWithoutCharge.
  ///
  /// In en, this message translates to:
  /// **'Cancelled without charge'**
  String get cancelledWithoutCharge;

  /// No description provided for @cancelThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelThisBooking;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// Application message: caseStatementValue
  ///
  /// In en, this message translates to:
  /// **'Case statement: {value}'**
  String caseStatementValue(String value);

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cashConfirmedByBoth.
  ///
  /// In en, this message translates to:
  /// **'Cash confirmed by both'**
  String get cashConfirmedByBoth;

  /// No description provided for @cashConfirmedByBothParties.
  ///
  /// In en, this message translates to:
  /// **'Cash confirmed by both parties'**
  String get cashConfirmedByBothParties;

  /// No description provided for @cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts.
  ///
  /// In en, this message translates to:
  /// **'Cash confirmed by both parties, after returns. Filtered by trip end date. Amounts under review are excluded.'**
  String get cashConfirmedByBothPartiesAfterReturnsFilteredByTripEndDateAmounts;

  /// No description provided for @cashNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cash not confirmed'**
  String get cashNotConfirmed;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get cashPayment;

  /// No description provided for @cashReturn.
  ///
  /// In en, this message translates to:
  /// **'Cash return'**
  String get cashReturn;

  /// No description provided for @cashReturnConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cash return confirmed'**
  String get cashReturnConfirmed;

  /// No description provided for @cashReturnOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Cash return outstanding'**
  String get cashReturnOutstanding;

  /// No description provided for @cashToReturn.
  ///
  /// In en, this message translates to:
  /// **'Cash to return'**
  String get cashToReturn;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @centerLatitude.
  ///
  /// In en, this message translates to:
  /// **'Center latitude'**
  String get centerLatitude;

  /// No description provided for @centerLongitude.
  ///
  /// In en, this message translates to:
  /// **'Center longitude'**
  String get centerLongitude;

  /// No description provided for @changingServiceCapacityRequiresAdministratorApprovalBeforeYouCanGoOnlineAgain.
  ///
  /// In en, this message translates to:
  /// **'Changing service capacity requires administrator approval before you can go online again.'**
  String
  get changingServiceCapacityRequiresAdministratorApprovalBeforeYouCanGoOnlineAgain;

  /// No description provided for @checkApproval.
  ///
  /// In en, this message translates to:
  /// **'Check approval'**
  String get checkApproval;

  /// No description provided for @checkingGpsAndPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking GPS and permission.'**
  String get checkingGpsAndPermission;

  /// No description provided for @checkLocally.
  ///
  /// In en, this message translates to:
  /// **'Check locally'**
  String get checkLocally;

  /// No description provided for @checkoutCouldNotBeCreated.
  ///
  /// In en, this message translates to:
  /// **'Checkout could not be created.'**
  String get checkoutCouldNotBeCreated;

  /// Application message: checkOutInBustosBulacanValue
  ///
  /// In en, this message translates to:
  /// **'Check out {value} in Bustos, Bulacan! 🏝️'**
  String checkOutInBustosBulacanValue(String value);

  /// No description provided for @checkRoadRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Check road restrictions'**
  String get checkRoadRestrictions;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @chooseABarangayAndEnterTheExactAddressBelow.
  ///
  /// In en, this message translates to:
  /// **'Choose a barangay and enter the exact address below'**
  String get chooseABarangayAndEnterTheExactAddressBelow;

  /// No description provided for @chooseAnExactPickupPointBeforeBooking.
  ///
  /// In en, this message translates to:
  /// **'Choose an exact pickup point before booking'**
  String get chooseAnExactPickupPointBeforeBooking;

  /// No description provided for @chooseAPickupPointOnTheMapOrEnableLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a pickup point on the map or enable location first.'**
  String get chooseAPickupPointOnTheMapOrEnableLocationFirst;

  /// No description provided for @chooseBothDocumentsAndExpiryDates.
  ///
  /// In en, this message translates to:
  /// **'Choose both documents and expiry dates.'**
  String get chooseBothDocumentsAndExpiryDates;

  /// No description provided for @chooseFranchiseExpiry.
  ///
  /// In en, this message translates to:
  /// **'Choose franchise expiry'**
  String get chooseFranchiseExpiry;

  /// Application message: chooseHowYouWantToUseApp
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use {brandName}'**
  String chooseHowYouWantToUseApp(String brandName);

  /// No description provided for @chooseJpegDocumentImages.
  ///
  /// In en, this message translates to:
  /// **'Choose JPEG document images.'**
  String get chooseJpegDocumentImages;

  /// No description provided for @chooseLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'Choose license expiry'**
  String get chooseLicenseExpiry;

  /// No description provided for @chooseLicenseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose license image'**
  String get chooseLicenseImage;

  /// No description provided for @choosePickupDate.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup date'**
  String get choosePickupDate;

  /// No description provided for @choosePickupTime.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup time'**
  String get choosePickupTime;

  /// No description provided for @choosePlacesSeeYourFareBookARide.
  ///
  /// In en, this message translates to:
  /// **'Choose places, see your fare, book a ride.'**
  String get choosePlacesSeeYourFareBookARide;

  /// No description provided for @chooseThePlacesYouWantToVisitInOneTrip.
  ///
  /// In en, this message translates to:
  /// **'Choose the places you want to visit in one trip.'**
  String get chooseThePlacesYouWantToVisitInOneTrip;

  /// No description provided for @chooseVehicleRegistrationImage.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle registration image'**
  String get chooseVehicleRegistrationImage;

  /// No description provided for @chooseWhoShouldReceiveThisAnnouncementThenReviewBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Choose who should receive this announcement, then review before sending.'**
  String get chooseWhoShouldReceiveThisAnnouncementThenReviewBeforeSending;

  /// No description provided for @chooseYourWorkspaceThenSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose your workspace, then sign in to continue.'**
  String get chooseYourWorkspaceThenSignInToContinue;

  /// No description provided for @church.
  ///
  /// In en, this message translates to:
  /// **'Church'**
  String get church;

  /// No description provided for @cleanVehicle.
  ///
  /// In en, this message translates to:
  /// **'Clean vehicle'**
  String get cleanVehicle;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @closeAndNotify.
  ///
  /// In en, this message translates to:
  /// **'Close and notify'**
  String get closeAndNotify;

  /// No description provided for @closeAttractionDetails.
  ///
  /// In en, this message translates to:
  /// **'Close attraction details'**
  String get closeAttractionDetails;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @closeTemporarily.
  ///
  /// In en, this message translates to:
  /// **'Close temporarily'**
  String get closeTemporarily;

  /// No description provided for @closureReason.
  ///
  /// In en, this message translates to:
  /// **'Closure reason'**
  String get closureReason;

  /// No description provided for @codeReissueCouldNotBeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Code reissue could not be confirmed.'**
  String get codeReissueCouldNotBeConfirmed;

  /// Application message: compactCurrency
  ///
  /// In en, this message translates to:
  /// **'₱{value}k'**
  String compactCurrency(String value);

  /// No description provided for @completeAllDocumentAndServiceAreaFields.
  ///
  /// In en, this message translates to:
  /// **'Complete all document and service-area fields.'**
  String get completeAllDocumentAndServiceAreaFields;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedAndActiveBookings.
  ///
  /// In en, this message translates to:
  /// **'Completed and active bookings'**
  String get completedAndActiveBookings;

  /// No description provided for @completedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get completedTrips;

  /// No description provided for @completeRefund.
  ///
  /// In en, this message translates to:
  /// **'Complete refund'**
  String get completeRefund;

  /// No description provided for @completeTestModeRefund.
  ///
  /// In en, this message translates to:
  /// **'Complete test-mode refund?'**
  String get completeTestModeRefund;

  /// No description provided for @completeTestModeRefundLabel.
  ///
  /// In en, this message translates to:
  /// **'Complete test-mode refund'**
  String get completeTestModeRefundLabel;

  /// No description provided for @completeTripCashStillUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Complete trip · cash still unconfirmed'**
  String get completeTripCashStillUnconfirmed;

  /// No description provided for @complianceApproved.
  ///
  /// In en, this message translates to:
  /// **'Compliance approved'**
  String get complianceApproved;

  /// No description provided for @complianceReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Compliance review required'**
  String get complianceReviewRequired;

  /// No description provided for @complianceReviewSaved.
  ///
  /// In en, this message translates to:
  /// **'Compliance review saved.'**
  String get complianceReviewSaved;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmAmount.
  ///
  /// In en, this message translates to:
  /// **'Confirm amount'**
  String get confirmAmount;

  /// No description provided for @confirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm and send'**
  String get confirmAndSend;

  /// No description provided for @confirmCashExchanged.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash exchanged?'**
  String get confirmCashExchanged;

  /// No description provided for @confirmCashPaid.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash paid'**
  String get confirmCashPaid;

  /// No description provided for @confirmCashReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash received'**
  String get confirmCashReceived;

  /// No description provided for @confirmCashReturned.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash returned?'**
  String get confirmCashReturned;

  /// No description provided for @confirmCashReturnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash returned'**
  String get confirmCashReturnedLabel;

  /// No description provided for @confirmCashReturnReceived.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash return received'**
  String get confirmCashReturnReceived;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm change'**
  String get confirmChange;

  /// No description provided for @confirmedCash.
  ///
  /// In en, this message translates to:
  /// **'Confirmed cash'**
  String get confirmedCash;

  /// No description provided for @confirmedEntriesArePermanentAndCannotBeEditedOrDeleted.
  ///
  /// In en, this message translates to:
  /// **'Confirmed entries are permanent and cannot be edited or deleted.'**
  String get confirmedEntriesArePermanentAndCannotBeEditedOrDeleted;

  /// No description provided for @confirmedTransactionsOnlyOpenReviewsAndOutstandingRefundsAreExcluded.
  ///
  /// In en, this message translates to:
  /// **'Confirmed transactions only. Open reviews and outstanding refunds are excluded.'**
  String
  get confirmedTransactionsOnlyOpenReviewsAndOutstandingRefundsAreExcluded;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNoShow.
  ///
  /// In en, this message translates to:
  /// **'Confirm no-show'**
  String get confirmNoShow;

  /// Application message: confirmOnlyAfterHasPhysicallyChangedHandsTheOtherPartyMustConfirmTooValue
  ///
  /// In en, this message translates to:
  /// **'Confirm only after {value} has physically changed hands. The other party must confirm too. Do not confirm a promised or partial payment.'**
  String
  confirmOnlyAfterHasPhysicallyChangedHandsTheOtherPartyMustConfirmTooValue(
    String value,
  );

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmRefund.
  ///
  /// In en, this message translates to:
  /// **'Confirm refund'**
  String get confirmRefund;

  /// Application message: confirmThatYouStayedAtTheVerifiedPickupPointUntilTheWaitingPeriodValue
  ///
  /// In en, this message translates to:
  /// **'Confirm that you stayed at the verified pickup point until the waiting period ended and tried to contact the tourist. The published {value}% no-show fee is {secondValue}. This action is recorded and can be disputed.'**
  String confirmThatYouStayedAtTheVerifiedPickupPointUntilTheWaitingPeriodValue(
    String value,
    String secondValue,
  );

  /// No description provided for @confirmThePickupPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm the pickup pin'**
  String get confirmThePickupPin;

  /// No description provided for @confirmYourEmailThenSignInAsADriverToFinishUploadingYour.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email, then sign in as a driver to finish uploading your application.'**
  String get confirmYourEmailThenSignInAsADriverToFinishUploadingYour;

  /// No description provided for @connectionUnavailableCheckYourInternetConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Connection unavailable. Check your internet connection and try again.'**
  String get connectionUnavailableCheckYourInternetConnectionAndTryAgain;

  /// No description provided for @connectToTheInternetAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet and retry.'**
  String get connectToTheInternetAndRetry;

  /// No description provided for @contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown.
  ///
  /// In en, this message translates to:
  /// **'Contact updates are unavailable. Only the national fallback is shown.'**
  String get contactUpdatesAreUnavailableOnlyTheNationalFallbackIsShown;

  /// No description provided for @couldNotGetACurrentGpsPositionCheckYourSignalAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not get a current GPS position. Check your signal and try again.'**
  String get couldNotGetACurrentGpsPositionCheckYourSignalAndTryAgain;

  /// No description provided for @couldNotGoOfflineLocationSharingRemainsActiveUntilTheServerConfirmsIt.
  ///
  /// In en, this message translates to:
  /// **'Could not go offline. Location sharing remains active until the server confirms it.'**
  String
  get couldNotGoOfflineLocationSharingRemainsActiveUntilTheServerConfirmsIt;

  /// No description provided for @couldNotGoOnlineYourAvailabilityWasNotChanged.
  ///
  /// In en, this message translates to:
  /// **'Could not go online. Your availability was not changed.'**
  String get couldNotGoOnlineYourAvailabilityWasNotChanged;

  /// No description provided for @couldNotLaunchPhoneDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer'**
  String get couldNotLaunchPhoneDialer;

  /// Application message: couldNotLaunchValue
  ///
  /// In en, this message translates to:
  /// **'Could not launch {value}'**
  String couldNotLaunchValue(String value);

  /// No description provided for @couldNotOpenCheckoutResumePaymentFromThisBooking.
  ///
  /// In en, this message translates to:
  /// **'Could not open checkout. Resume payment from this booking.'**
  String get couldNotOpenCheckoutResumePaymentFromThisBooking;

  /// No description provided for @couldNotOpenMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not open messages.'**
  String get couldNotOpenMessages;

  /// No description provided for @couldNotOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Could not open navigation.'**
  String get couldNotOpenNavigation;

  /// No description provided for @couldNotOpenPhoneDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone dialer.'**
  String get couldNotOpenPhoneDialer;

  /// No description provided for @couldNotOpenThePhoneDialerCall911Manually.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer. Call 911 manually.'**
  String get couldNotOpenThePhoneDialerCall911Manually;

  /// No description provided for @couldNotOpenThePhoneDialerCallTheDisplayedNumberManually.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone dialer. Call the displayed number manually.'**
  String get couldNotOpenThePhoneDialerCallTheDisplayedNumberManually;

  /// No description provided for @couldNotOpenThisDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not open this document.'**
  String get couldNotOpenThisDocument;

  /// No description provided for @couldNotSaveNoBookingOrPaymentStateWasChanged.
  ///
  /// In en, this message translates to:
  /// **'Could not save. No booking or payment state was changed.'**
  String get couldNotSaveNoBookingOrPaymentStateWasChanged;

  /// No description provided for @couldNotSaveThisChangePleaseRetryThePreviousTripStateHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Could not save this change. Please retry; the previous trip state has been kept.'**
  String get couldNotSaveThisChangePleaseRetryThePreviousTripStateHasBeen;

  /// No description provided for @couldNotSynchronizeWithTheServerCheckYourConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not synchronize with the server. Check your connection and retry.'**
  String get couldNotSynchronizeWithTheServerCheckYourConnectionAndRetry;

  /// No description provided for @createANewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get createANewPassword;

  /// No description provided for @createTouristAccount.
  ///
  /// In en, this message translates to:
  /// **'Create tourist account'**
  String get createTouristAccount;

  /// No description provided for @criticalConditionsAlsoAppearInOperationalAlertsInvestigateBeforeClearingAnAlert.
  ///
  /// In en, this message translates to:
  /// **'Critical conditions also appear in operational alerts. Investigate before clearing an alert.'**
  String
  get criticalConditionsAlsoAppearInOperationalAlertsInvestigateBeforeClearingAnAlert;

  /// No description provided for @curatedExperience.
  ///
  /// In en, this message translates to:
  /// **'Curated experience'**
  String get curatedExperience;

  /// No description provided for @currentGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Current GPS location'**
  String get currentGpsLocation;

  /// No description provided for @currentGpsPickup.
  ///
  /// In en, this message translates to:
  /// **'Current GPS pickup'**
  String get currentGpsPickup;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @customTour.
  ///
  /// In en, this message translates to:
  /// **'Custom tour'**
  String get customTour;

  /// No description provided for @customTour112SelectedStops.
  ///
  /// In en, this message translates to:
  /// **'Custom tour (1–12 selected stops)'**
  String get customTour112SelectedStops;

  /// Application message: customTourNewBookingsUseTheseRatesExistingBookingsKeepTheirAgreedFareValue
  ///
  /// In en, this message translates to:
  /// **'Custom tour: ₱{value}\n{secondValue}\n\nNew bookings use these rates. Existing bookings keep their agreed fare.'**
  String
  customTourNewBookingsUseTheseRatesExistingBookingsKeepTheirAgreedFareValue(
    String value,
    String secondValue,
  );

  /// No description provided for @dataExportRequests.
  ///
  /// In en, this message translates to:
  /// **'Data export requests'**
  String get dataExportRequests;

  /// Application message: daysAgoValue
  ///
  /// In en, this message translates to:
  /// **'{value} days ago'**
  String daysAgoValue(String value);

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @decisionAndReasoning.
  ///
  /// In en, this message translates to:
  /// **'Decision and reasoning'**
  String get decisionAndReasoning;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @decliningMatchedOffersRequiresTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'Declining matched offers requires the configured server.'**
  String get decliningMatchedOffersRequiresTheConfiguredServer;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccount;

  /// Application message: deletedValue
  ///
  /// In en, this message translates to:
  /// **'{value} deleted'**
  String deletedValue(String value);

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get deletingAccount;

  /// No description provided for @deletionPending.
  ///
  /// In en, this message translates to:
  /// **'Deletion pending'**
  String get deletionPending;

  /// No description provided for @describeTheDisagreementCollectionAndRefundConfirmationsWillPauseUntilAnAdminReviews.
  ///
  /// In en, this message translates to:
  /// **'Describe the disagreement. Collection and refund confirmations will pause until an admin reviews it.'**
  String
  get describeTheDisagreementCollectionAndRefundConfirmationsWillPauseUntilAnAdminReviews;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @destinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get destinations;

  /// No description provided for @destinationsYouLove.
  ///
  /// In en, this message translates to:
  /// **'Destinations you love'**
  String get destinationsYouLove;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @directionsRequireBetween2And25Coordinates.
  ///
  /// In en, this message translates to:
  /// **'Directions require between 2 and 25 coordinates.'**
  String get directionsRequireBetween2And25Coordinates;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @discoverBustos.
  ///
  /// In en, this message translates to:
  /// **'Discover Bustos'**
  String get discoverBustos;

  /// No description provided for @disputePaymentReportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Dispute payment / report a problem'**
  String get disputePaymentReportAProblem;

  /// Application message: distanceKilometers
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKilometers(String value);

  /// Application message: distanceMeters
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String distanceMeters(String value);

  /// Application message: documentsAreWaitingForVerificationValue
  ///
  /// In en, this message translates to:
  /// **'{value} documents are waiting for verification'**
  String documentsAreWaitingForVerificationValue(String value);

  /// No description provided for @documentsDatesServiceAreaAndReliabilityMeetTheMatchingRules.
  ///
  /// In en, this message translates to:
  /// **'Documents, dates, service area, and reliability meet the matching rules.'**
  String get documentsDatesServiceAreaAndReliabilityMeetTheMatchingRules;

  /// No description provided for @documentsPassword.
  ///
  /// In en, this message translates to:
  /// **'Documents & password'**
  String get documentsPassword;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @donTHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get donTHaveAnAccount;

  /// No description provided for @downloadExport.
  ///
  /// In en, this message translates to:
  /// **'Download export'**
  String get downloadExport;

  /// No description provided for @dragTheMapToPinYourExactLocation.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to pin your exact location'**
  String get dragTheMapToPinYourExactLocation;

  /// No description provided for @drive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get drive;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @driverAcceptedTheFixedFareAndPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted the fixed fare and pickup.'**
  String get driverAcceptedTheFixedFareAndPickup;

  /// No description provided for @driverAccount.
  ///
  /// In en, this message translates to:
  /// **'Driver account'**
  String get driverAccount;

  /// No description provided for @driverApplication.
  ///
  /// In en, this message translates to:
  /// **'Driver application'**
  String get driverApplication;

  /// No description provided for @driverApprovedAndMatchingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Driver approved and matching enabled.'**
  String get driverApprovedAndMatchingEnabled;

  /// No description provided for @driverArrival.
  ///
  /// In en, this message translates to:
  /// **'Driver arrival'**
  String get driverArrival;

  /// No description provided for @driverArrivedAtTheVerifiedPickupAreaTheWaitingPeriodStarted.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived at the verified pickup area. The waiting period started.'**
  String get driverArrivedAtTheVerifiedPickupAreaTheWaitingPeriodStarted;

  /// No description provided for @driverBookings.
  ///
  /// In en, this message translates to:
  /// **'Driver bookings'**
  String get driverBookings;

  /// No description provided for @driverCancellationRateExceedsThe30MatchingLimit.
  ///
  /// In en, this message translates to:
  /// **'Driver cancellation rate exceeds the 30% matching limit.'**
  String get driverCancellationRateExceedsThe30MatchingLimit;

  /// No description provided for @driverCancellations.
  ///
  /// In en, this message translates to:
  /// **'Driver cancellations'**
  String get driverCancellations;

  /// No description provided for @driverCompliance.
  ///
  /// In en, this message translates to:
  /// **'Driver compliance'**
  String get driverCompliance;

  /// No description provided for @driverComplianceRecordsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Driver compliance records will appear here.'**
  String get driverComplianceRecordsWillAppearHere;

  /// No description provided for @driverConcern.
  ///
  /// In en, this message translates to:
  /// **'Driver concern'**
  String get driverConcern;

  /// No description provided for @driverDocumentsMustBeJpegImages5MbMaximumEach.
  ///
  /// In en, this message translates to:
  /// **'Driver documents must be JPEG images, 5 MB maximum each.'**
  String get driverDocumentsMustBeJpegImages5MbMaximumEach;

  /// No description provided for @driverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived'**
  String get driverHasArrived;

  /// No description provided for @driverIsMoving.
  ///
  /// In en, this message translates to:
  /// **'Driver is moving'**
  String get driverIsMoving;

  /// No description provided for @driverIsStopped.
  ///
  /// In en, this message translates to:
  /// **'Driver is stopped'**
  String get driverIsStopped;

  /// No description provided for @driverLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver license'**
  String get driverLicense;

  /// No description provided for @driverLicenseDocumentIsMissing.
  ///
  /// In en, this message translates to:
  /// **'Driver license document is missing.'**
  String get driverLicenseDocumentIsMissing;

  /// No description provided for @driverLicenseExpiry.
  ///
  /// In en, this message translates to:
  /// **'Driver license expiry'**
  String get driverLicenseExpiry;

  /// No description provided for @driverMatchingBegins30MinutesBeforePickup.
  ///
  /// In en, this message translates to:
  /// **'Driver matching begins 30 minutes before pickup.'**
  String get driverMatchingBegins30MinutesBeforePickup;

  /// No description provided for @driverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver not found'**
  String get driverNotFound;

  /// No description provided for @driverPerformance.
  ///
  /// In en, this message translates to:
  /// **'Driver performance'**
  String get driverPerformance;

  /// No description provided for @driverRegistration.
  ///
  /// In en, this message translates to:
  /// **'Driver registration'**
  String get driverRegistration;

  /// No description provided for @driverReplacementRequested.
  ///
  /// In en, this message translates to:
  /// **'Driver replacement requested'**
  String get driverReplacementRequested;

  /// No description provided for @driverReplacementRequiresTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'Driver replacement requires the configured server.'**
  String get driverReplacementRequiresTheConfiguredServer;

  /// No description provided for @driverReportedArrivalAwaitingTourist.
  ///
  /// In en, this message translates to:
  /// **'Driver reported arrival · awaiting tourist'**
  String get driverReportedArrivalAwaitingTourist;

  /// No description provided for @driverReviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Driver review submitted.'**
  String get driverReviewSubmitted;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// Application message: driversActiveValue
  ///
  /// In en, this message translates to:
  /// **'Active drivers: {value}'**
  String driversActiveValue(String value);

  /// No description provided for @driverSearchRetriedForAnother10Minutes.
  ///
  /// In en, this message translates to:
  /// **'Driver search retried for another 10 minutes.'**
  String get driverSearchRetriedForAnother10Minutes;

  /// Application message: driversHaveToAcceptThisSearchRequestYouCanLeaveThisScreenAndValue
  ///
  /// In en, this message translates to:
  /// **'Drivers have {value} to accept this search request. You can leave this screen and return through Trips. No fare is charged while waiting.'**
  String driversHaveToAcceptThisSearchRequestYouCanLeaveThisScreenAndValue(
    String value,
  );

  /// No description provided for @driverSuspendedFor30Days.
  ///
  /// In en, this message translates to:
  /// **'Driver suspended for 30 days.'**
  String get driverSuspendedFor30Days;

  /// No description provided for @driverTools.
  ///
  /// In en, this message translates to:
  /// **'Driver tools'**
  String get driverTools;

  /// No description provided for @driverTrackingPreview.
  ///
  /// In en, this message translates to:
  /// **'Driver tracking preview'**
  String get driverTrackingPreview;

  /// Application message: driverValue
  ///
  /// In en, this message translates to:
  /// **'Driver: {value}'**
  String driverValue(String value);

  /// No description provided for @driverVerifications.
  ///
  /// In en, this message translates to:
  /// **'Driver verifications'**
  String get driverVerifications;

  /// No description provided for @eachDriverDocumentMustBe5MbOrSmaller.
  ///
  /// In en, this message translates to:
  /// **'Each driver document must be 5 MB or smaller.'**
  String get eachDriverDocumentMustBe5MbOrSmaller;

  /// No description provided for @earlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @earningsInsights.
  ///
  /// In en, this message translates to:
  /// **'Earnings insights'**
  String get earningsInsights;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editTouristSpot.
  ///
  /// In en, this message translates to:
  /// **'Edit tourist spot'**
  String get editTouristSpot;

  /// No description provided for @eG123RizalStNearTheBakery.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123 Rizal St. near the bakery'**
  String get eG123RizalStNearTheBakery;

  /// No description provided for @eGMinasaFestivalGrounds.
  ///
  /// In en, this message translates to:
  /// **'e.g. Minasa Festival Grounds'**
  String get eGMinasaFestivalGrounds;

  /// No description provided for @eGSystemMaintenance.
  ///
  /// In en, this message translates to:
  /// **'e.g. System maintenance'**
  String get eGSystemMaintenance;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailAddressIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required'**
  String get emailAddressIsRequired;

  /// Application message: emailAddressMustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'Email address must not exceed {value} characters'**
  String emailAddressMustNotExceedCharactersValue(String value);

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @emailReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Email (read-only)'**
  String get emailReadOnly;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @emergencyContactsSettings.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts settings'**
  String get emergencyContactsSettings;

  /// No description provided for @emergencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Emergency help'**
  String get emergencyHelp;

  /// No description provided for @emergencySafety.
  ///
  /// In en, this message translates to:
  /// **'Emergency & safety'**
  String get emergencySafety;

  /// No description provided for @endSafelyReviewPayment.
  ///
  /// In en, this message translates to:
  /// **'End safely · review payment'**
  String get endSafelyReviewPayment;

  /// No description provided for @endTheTourSafelyFirstToOpenASettlementReview.
  ///
  /// In en, this message translates to:
  /// **'End the tour safely first to open a settlement review.'**
  String get endTheTourSafelyFirstToOpenASettlementReview;

  /// No description provided for @endTourEarly.
  ///
  /// In en, this message translates to:
  /// **'End tour early?'**
  String get endTourEarly;

  /// No description provided for @endTourEarlyReportAProblem.
  ///
  /// In en, this message translates to:
  /// **'End tour early / report a problem'**
  String get endTourEarlyReportAProblem;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @englishName.
  ///
  /// In en, this message translates to:
  /// **'English name'**
  String get englishName;

  /// No description provided for @enterAClearClosureReason.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear closure reason.'**
  String get enterAClearClosureReason;

  /// No description provided for @enterAClearReasonForTheAuditHistory.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear reason for the audit history'**
  String get enterAClearReasonForTheAuditHistory;

  /// No description provided for @enterAClearReasonForThisChange.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear reason for this change.'**
  String get enterAClearReasonForThisChange;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address...'**
  String get enterAddress;

  /// No description provided for @enterAnAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter an admin email'**
  String get enterAnAdminEmail;

  /// No description provided for @enterAPhMobileNumberOrInternationalNumberWithCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a PH mobile number or international number with +country code'**
  String get enterAPhMobileNumberOrInternationalNumberWithCountryCode;

  /// No description provided for @enterAPriceBetween001And100000.
  ///
  /// In en, this message translates to:
  /// **'Enter a price between ₱0.01 and ₱100,000.'**
  String get enterAPriceBetween001And100000;

  /// No description provided for @enterAReasonOfAtLeastFiveCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason of at least five characters.'**
  String get enterAReasonOfAtLeastFiveCharacters;

  /// No description provided for @enterAValidAmountWithAtMostTwoDecimals.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount with at most two decimals.'**
  String get enterAValidAmountWithAtMostTwoDecimals;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterAValidEmail;

  /// No description provided for @enterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterAValidPhoneNumber;

  /// No description provided for @enterAValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterAValidPrice;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description...'**
  String get enterDescription;

  /// No description provided for @enterDriverApp.
  ///
  /// In en, this message translates to:
  /// **'Enter driver app'**
  String get enterDriverApp;

  /// No description provided for @enterHistory.
  ///
  /// In en, this message translates to:
  /// **'Enter history...'**
  String get enterHistory;

  /// No description provided for @enterPesosWithAtMostTwoDecimalPlaces.
  ///
  /// In en, this message translates to:
  /// **'Enter pesos with at most two decimal places.'**
  String get enterPesosWithAtMostTwoDecimalPlaces;

  /// No description provided for @enterThePickupAddressBelow.
  ///
  /// In en, this message translates to:
  /// **'Enter the pickup address below.'**
  String get enterThePickupAddressBelow;

  /// No description provided for @enterTheReasonForApprovingOrRestoringServiceAtLeastFiveCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter the reason for approving or restoring service (at least five characters).'**
  String get enterTheReasonForApprovingOrRestoringServiceAtLeastFiveCharacters;

  /// No description provided for @enterTouristApp.
  ///
  /// In en, this message translates to:
  /// **'Enter tourist app'**
  String get enterTouristApp;

  /// No description provided for @enterValidFixedFaresForEveryRoute.
  ///
  /// In en, this message translates to:
  /// **'Enter valid fixed fares for every route.'**
  String get enterValidFixedFaresForEveryRoute;

  /// No description provided for @enterYourAnnouncementDetailsHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your announcement details here...'**
  String get enterYourAnnouncementDetailsHere;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourEmailAndWeWillSendYouALinkToResetYour.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password.'**
  String get enterYourEmailAndWeWillSendYouALinkToResetYour;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @entranceFee.
  ///
  /// In en, this message translates to:
  /// **'Entrance fee'**
  String get entranceFee;

  /// No description provided for @entranceFeesMayApply.
  ///
  /// In en, this message translates to:
  /// **'+ entrance fees may apply'**
  String get entranceFeesMayApply;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eta;

  /// No description provided for @exampleEmailCom.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get exampleEmailCom;

  /// No description provided for @exampleSeniorPassengerNeedsExtraBoardingTime.
  ///
  /// In en, this message translates to:
  /// **'Example: senior passenger needs extra boarding time'**
  String get exampleSeniorPassengerNeedsExtraBoardingTime;

  /// No description provided for @exampleTwoBackpacksAndOneFoldingStroller.
  ///
  /// In en, this message translates to:
  /// **'Example: two backpacks and one folding stroller'**
  String get exampleTwoBackpacksAndOneFoldingStroller;

  /// No description provided for @exampleUpdatedOperatingCostApprovedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Example: Updated operating cost approved by admin'**
  String get exampleUpdatedOperatingCostApprovedByAdmin;

  /// No description provided for @expectedReopening.
  ///
  /// In en, this message translates to:
  /// **'Expected reopening'**
  String get expectedReopening;

  /// Application message: expectedReopeningValue
  ///
  /// In en, this message translates to:
  /// **'Expected reopening: {value}'**
  String expectedReopeningValue(String value);

  /// Application message: expiryIsNotVerifiedValue
  ///
  /// In en, this message translates to:
  /// **'{value} expiry is not verified.'**
  String expiryIsNotVerifiedValue(String value);

  /// No description provided for @expiryVerification.
  ///
  /// In en, this message translates to:
  /// **'Expiry verification'**
  String get expiryVerification;

  /// No description provided for @explainAnythingTheDriverMustCorrect.
  ///
  /// In en, this message translates to:
  /// **'Explain anything the driver must correct'**
  String get explainAnythingTheDriverMustCorrect;

  /// No description provided for @explainTheDecisionAtLeast10Characters.
  ///
  /// In en, this message translates to:
  /// **'Explain the decision (at least 10 characters).'**
  String get explainTheDecisionAtLeast10Characters;

  /// No description provided for @explainTheDecisionClearly.
  ///
  /// In en, this message translates to:
  /// **'Explain the decision clearly'**
  String get explainTheDecisionClearly;

  /// No description provided for @explainThePolicyInAtLeast20Characters.
  ///
  /// In en, this message translates to:
  /// **'Explain the policy in at least 20 characters.'**
  String get explainThePolicyInAtLeast20Characters;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @exploreBustos.
  ///
  /// In en, this message translates to:
  /// **'Explore Bustos'**
  String get exploreBustos;

  /// No description provided for @exploreSpotsBuildItinerariesAndBookTricyclesEasily.
  ///
  /// In en, this message translates to:
  /// **'Explore spots, build itineraries, and book tricycles easily.'**
  String get exploreSpotsBuildItinerariesAndBookTricyclesEasily;

  /// No description provided for @exploreTheHeritageNatureAndBeautyOfBustosBulacanWithEase.
  ///
  /// In en, this message translates to:
  /// **'Explore the heritage, nature, and beauty of Bustos, Bulacan with ease.'**
  String get exploreTheHeritageNatureAndBeautyOfBustosBulacanWithEase;

  /// No description provided for @exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited.
  ///
  /// In en, this message translates to:
  /// **'Exports are delivered only to the requesting account. Fulfilment is audited.'**
  String get exportsAreDeliveredOnlyToTheRequestingAccountFulfilmentIsAudited;

  /// No description provided for @f123456.
  ///
  /// In en, this message translates to:
  /// **'F-123456'**
  String get f123456;

  /// No description provided for @failedPayments.
  ///
  /// In en, this message translates to:
  /// **'Failed payments'**
  String get failedPayments;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackMarkedResolved.
  ///
  /// In en, this message translates to:
  /// **'Feedback marked resolved'**
  String get feedbackMarkedResolved;

  /// No description provided for @feedbackSubmittedThankYou.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent. Thank you!'**
  String get feedbackSubmittedThankYou;

  /// No description provided for @filipino.
  ///
  /// In en, this message translates to:
  /// **'Filipino'**
  String get filipino;

  /// No description provided for @filipinoName.
  ///
  /// In en, this message translates to:
  /// **'Filipino name'**
  String get filipinoName;

  /// No description provided for @finalCharge.
  ///
  /// In en, this message translates to:
  /// **'Final charge (₱)'**
  String get finalCharge;

  /// No description provided for @finalChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Final charge'**
  String get finalChargeLabel;

  /// Application message: finalChargeValue
  ///
  /// In en, this message translates to:
  /// **'Final charge: ₱{value} · {secondValue}'**
  String finalChargeValue(String value, String secondValue);

  /// No description provided for @financeAdministratorAccessIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Finance administrator access is required.'**
  String get financeAdministratorAccessIsRequired;

  /// No description provided for @financialRecord.
  ///
  /// In en, this message translates to:
  /// **'Financial record'**
  String get financialRecord;

  /// No description provided for @findADriver.
  ///
  /// In en, this message translates to:
  /// **'Find a driver'**
  String get findADriver;

  /// No description provided for @findAnotherDriver.
  ///
  /// In en, this message translates to:
  /// **'Find another driver'**
  String get findAnotherDriver;

  /// No description provided for @findAnotherDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Find another driver?'**
  String get findAnotherDriverLabel;

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get findingYourLocation;

  /// No description provided for @findMyDriver.
  ///
  /// In en, this message translates to:
  /// **'Find my driver'**
  String get findMyDriver;

  /// No description provided for @finishOrCancelTheActiveTripBeforeGoingOffline.
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel the active trip before going offline.'**
  String get finishOrCancelTheActiveTripBeforeGoingOffline;

  /// No description provided for @finishYourCurrentTripBeforeAcceptingAnother.
  ///
  /// In en, this message translates to:
  /// **'Finish your current trip before accepting another.'**
  String get finishYourCurrentTripBeforeAcceptingAnother;

  /// No description provided for @fixedFare.
  ///
  /// In en, this message translates to:
  /// **'Fixed fare'**
  String get fixedFare;

  /// Application message: fixedFareAcceptedCancellationPaymentPolicyV1AcceptedValue
  ///
  /// In en, this message translates to:
  /// **'Fixed fare ₱{value} accepted; cancellation/payment policy v1 accepted.'**
  String fixedFareAcceptedCancellationPaymentPolicyV1AcceptedValue(
    String value,
  );

  /// No description provided for @fixedFareForThisRoute.
  ///
  /// In en, this message translates to:
  /// **'Fixed fare for this route'**
  String get fixedFareForThisRoute;

  /// No description provided for @fixedFares.
  ///
  /// In en, this message translates to:
  /// **'Fixed fares'**
  String get fixedFares;

  /// No description provided for @fixedFaresSavedExistingBookingPricesAreUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Fixed fares saved. Existing booking prices are unchanged.'**
  String get fixedFaresSavedExistingBookingPricesAreUnchanged;

  /// Application message: fixedFareValue
  ///
  /// In en, this message translates to:
  /// **'Fixed fare: ₱{value}'**
  String fixedFareValue(String value);

  /// No description provided for @fixedItinerary.
  ///
  /// In en, this message translates to:
  /// **'Fixed itinerary'**
  String get fixedItinerary;

  /// No description provided for @flag.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get flag;

  /// Application message: flutterFailureValue
  ///
  /// In en, this message translates to:
  /// **'Flutter failure: {value}'**
  String flutterFailureValue(String value);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLabel;

  /// Application message: forImmediateDangerCall911AppDoesNotReplaceEmergencyServices
  ///
  /// In en, this message translates to:
  /// **'For immediate danger, call 911. {brandName} does not replace emergency services.'**
  String forImmediateDangerCall911AppDoesNotReplaceEmergencyServices(
    String brandName,
  );

  /// No description provided for @formattedValue.
  ///
  /// In en, this message translates to:
  /// **' → '**
  String get formattedValue;

  /// No description provided for @fr12345.
  ///
  /// In en, this message translates to:
  /// **'FR-12345'**
  String get fr12345;

  /// No description provided for @franchise.
  ///
  /// In en, this message translates to:
  /// **'Franchise'**
  String get franchise;

  /// No description provided for @franchiseExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'franchise_expires_on'**
  String get franchiseExpiresOn;

  /// No description provided for @franchiseExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Franchise expiry date'**
  String get franchiseExpiryDate;

  /// No description provided for @franchiseNumber.
  ///
  /// In en, this message translates to:
  /// **'Franchise number'**
  String get franchiseNumber;

  /// No description provided for @franchiseNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Franchise number is required'**
  String get franchiseNumberIsRequired;

  /// No description provided for @franchiseOrCr.
  ///
  /// In en, this message translates to:
  /// **'Franchise / OR-CR'**
  String get franchiseOrCr;

  /// No description provided for @franchiseOrCrDocumentIsMissing.
  ///
  /// In en, this message translates to:
  /// **'Franchise / OR-CR document is missing.'**
  String get franchiseOrCrDocumentIsMissing;

  /// No description provided for @franchiseOrCrExpiry.
  ///
  /// In en, this message translates to:
  /// **'Franchise / OR-CR expiry'**
  String get franchiseOrCrExpiry;

  /// No description provided for @franchiseOrCrLabel.
  ///
  /// In en, this message translates to:
  /// **'Franchise OR/CR'**
  String get franchiseOrCrLabel;

  /// No description provided for @franchiseOrCrNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Franchise/OR-CR number is required'**
  String get franchiseOrCrNumberIsRequired;

  /// Application message: franchiseOrCrNumberMustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'Franchise/OR-CR number must not exceed {value} characters'**
  String franchiseOrCrNumberMustNotExceedCharactersValue(String value);

  /// Application message: franchiseValue
  ///
  /// In en, this message translates to:
  /// **'Franchise: {value}'**
  String franchiseValue(String value);

  /// No description provided for @freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get freeCancellation;

  /// Application message: freeCancellationMinutesLateTouristCancellationVerifiedPickupWaitMinutesTouristNoShowValue
  ///
  /// In en, this message translates to:
  /// **'Free cancellation: {value} minutes\nLate tourist cancellation: {secondValue}%\nVerified pickup wait: {thirdValue} minutes\nTourist no-show fee: {fourthValue}%\n\nExisting bookings keep their original policy.'**
  String
  freeCancellationMinutesLateTouristCancellationVerifiedPickupWaitMinutesTouristNoShowValue(
    String value,
    String secondValue,
    String thirdValue,
    String fourthValue,
  );

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @fromPickup.
  ///
  /// In en, this message translates to:
  /// **'from pickup'**
  String get fromPickup;

  /// Application message: fromValue
  ///
  /// In en, this message translates to:
  /// **'{value} from {secondValue}'**
  String fromValue(String value, String secondValue);

  /// No description provided for @fromYou.
  ///
  /// In en, this message translates to:
  /// **'from you'**
  String get fromYou;

  /// No description provided for @fulfilled.
  ///
  /// In en, this message translates to:
  /// **'fulfilled'**
  String get fulfilled;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameIsRequired;

  /// No description provided for @getAroundQuicklyAndSafelyByBookingLocalTricycleDriversInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Get around quickly and safely by booking local tricycle drivers in seconds.'**
  String get getAroundQuicklyAndSafelyByBookingLocalTricycleDriversInSeconds;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Application message: goodMorningValue
  ///
  /// In en, this message translates to:
  /// **'Good morning, {value}'**
  String goodMorningValue(String value);

  /// No description provided for @goOnlineToActivateTheDriverMap.
  ///
  /// In en, this message translates to:
  /// **'Go online to activate the driver map.'**
  String get goOnlineToActivateTheDriverMap;

  /// No description provided for @goOnlineToStartReceivingBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'Go online to start receiving booking requests.'**
  String get goOnlineToStartReceivingBookingRequests;

  /// No description provided for @goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept.
  ///
  /// In en, this message translates to:
  /// **'Go online with an approved account and finish your current trip to accept a new request.'**
  String get goOnlineWithAnApprovedAccountAndFinishYourCurrentTripToAccept;

  /// No description provided for @goOnlineWithAnApprovedDriverAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Go online with an approved driver account first.'**
  String get goOnlineWithAnApprovedDriverAccountFirst;

  /// No description provided for @greatRideVeryKnowledgeableAboutBustos.
  ///
  /// In en, this message translates to:
  /// **'Great ride, very knowledgeable about Bustos!'**
  String get greatRideVeryKnowledgeableAboutBustos;

  /// No description provided for @headingTo.
  ///
  /// In en, this message translates to:
  /// **'Heading to'**
  String get headingTo;

  /// No description provided for @headingToPickup.
  ///
  /// In en, this message translates to:
  /// **'Heading to pickup'**
  String get headingToPickup;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @heritage.
  ///
  /// In en, this message translates to:
  /// **'Heritage'**
  String get heritage;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// Application message: hideValue
  ///
  /// In en, this message translates to:
  /// **'Hide {value}'**
  String hideValue(String value);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Application message: hoursAgoValue
  ///
  /// In en, this message translates to:
  /// **'{value} hours ago'**
  String hoursAgoValue(String value);

  /// Application message: howWasYourRideWithValue
  ///
  /// In en, this message translates to:
  /// **'How was your ride with {value}?'**
  String howWasYourRideWithValue(String value);

  /// No description provided for @iAgreeToTheFixedFareAndCancellationPaymentPolicy.
  ///
  /// In en, this message translates to:
  /// **'I agree to the fixed fare and cancellation/payment policy.'**
  String get iAgreeToTheFixedFareAndCancellationPaymentPolicy;

  /// No description provided for @iAgreeToTheTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms and conditions'**
  String get iAgreeToTheTermsAndConditions;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a...'**
  String get iAmA;

  /// No description provided for @ifPlansChange.
  ///
  /// In en, this message translates to:
  /// **'If plans change'**
  String get ifPlansChange;

  /// No description provided for @iHaveReadAndAcceptThisNotice.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept this notice.'**
  String get iHaveReadAndAcceptThisNotice;

  /// No description provided for @iHaveReadTheNoticeAndAgreeToTheDataUseNeededTo.
  ///
  /// In en, this message translates to:
  /// **'I have read the notice and agree to the data use needed to provide my account and trips.'**
  String get iHaveReadTheNoticeAndAgreeToTheDataUseNeededTo;

  /// No description provided for @imageContentMimeTypeAndFileExtensionMustMatch.
  ///
  /// In en, this message translates to:
  /// **'Image content, MIME type and file extension must match.'**
  String get imageContentMimeTypeAndFileExtensionMustMatch;

  /// No description provided for @includedStops.
  ///
  /// In en, this message translates to:
  /// **'Included stops'**
  String get includedStops;

  /// No description provided for @includeWhatHappenedWhereTheTripStoppedAndAnyCashAlreadyExchangedStatements.
  ///
  /// In en, this message translates to:
  /// **'Include what happened, where the trip stopped, and any cash already exchanged. Statements are retained with the booking.'**
  String
  get includeWhatHappenedWhereTheTripStoppedAndAnyCashAlreadyExchangedStatements;

  /// No description provided for @incomingBooking.
  ///
  /// In en, this message translates to:
  /// **'Incoming booking'**
  String get incomingBooking;

  /// No description provided for @incomingPickup.
  ///
  /// In en, this message translates to:
  /// **'Incoming pickup'**
  String get incomingPickup;

  /// Application message: informationProvidedByAppAdministrators
  ///
  /// In en, this message translates to:
  /// **'Information provided by {brandName} administrators'**
  String informationProvidedByAppAdministrators(String brandName);

  /// No description provided for @interactiveMapsAreAvailableInTheMobileApp.
  ///
  /// In en, this message translates to:
  /// **'Interactive maps are available in the mobile app.'**
  String get interactiveMapsAreAvailableInTheMobileApp;

  /// No description provided for @invalidAdminCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid admin credentials'**
  String get invalidAdminCredentials;

  /// No description provided for @invalidAppBuild.
  ///
  /// In en, this message translates to:
  /// **'Invalid app build'**
  String get invalidAppBuild;

  /// No description provided for @invalidAttractionImageOwner.
  ///
  /// In en, this message translates to:
  /// **'Invalid attraction image owner.'**
  String get invalidAttractionImageOwner;

  /// No description provided for @invalidAttractionImageVersion.
  ///
  /// In en, this message translates to:
  /// **'Invalid attraction image version.'**
  String get invalidAttractionImageVersion;

  /// No description provided for @invalidLatitude.
  ///
  /// In en, this message translates to:
  /// **'Invalid latitude'**
  String get invalidLatitude;

  /// No description provided for @invalidLongitude.
  ///
  /// In en, this message translates to:
  /// **'Invalid longitude'**
  String get invalidLongitude;

  /// Application message: isExpiredValue
  ///
  /// In en, this message translates to:
  /// **'{value} is expired.'**
  String isExpiredValue(String value);

  /// Application message: isNowHiddenValue
  ///
  /// In en, this message translates to:
  /// **'{value} is now hidden'**
  String isNowHiddenValue(String value);

  /// Application message: isNowVisibleValue
  ///
  /// In en, this message translates to:
  /// **'{value} is now visible'**
  String isNowVisibleValue(String value);

  /// Application message: isRequiredValue
  ///
  /// In en, this message translates to:
  /// **'{value} is required'**
  String isRequiredValue(String value);

  /// No description provided for @isTemporarilyClosedAndCannotBeAddedRightNow.
  ///
  /// In en, this message translates to:
  /// **'{spot} is temporarily closed and cannot be added right now.'**
  String isTemporarilyClosedAndCannotBeAddedRightNow(String spot);

  /// No description provided for @itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get itinerary;

  /// No description provided for @iVerifiedThisNumberWithTheAgency.
  ///
  /// In en, this message translates to:
  /// **'I verified this number with the agency.'**
  String get iVerifiedThisNumberWithTheAgency;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @johnDoe.
  ///
  /// In en, this message translates to:
  /// **'John doe'**
  String get johnDoe;

  /// No description provided for @johnExampleCom.
  ///
  /// In en, this message translates to:
  /// **'john@example.com'**
  String get johnExampleCom;

  /// No description provided for @juanDelaCruz.
  ///
  /// In en, this message translates to:
  /// **'Juan Dela Cruz'**
  String get juanDelaCruz;

  /// No description provided for @juanExampleCom.
  ///
  /// In en, this message translates to:
  /// **'juan@example.com'**
  String get juanExampleCom;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @keepAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get keepAccount;

  /// No description provided for @keepCurrentCode.
  ///
  /// In en, this message translates to:
  /// **'Keep current code'**
  String get keepCurrentCode;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @keepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep open'**
  String get keepOpen;

  /// No description provided for @keepOriginalRoute.
  ///
  /// In en, this message translates to:
  /// **'Keep original route'**
  String get keepOriginalRoute;

  /// No description provided for @keepUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Keep under review'**
  String get keepUnderReview;

  /// No description provided for @keepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get keepWaiting;

  /// Application message: kmAwayValue
  ///
  /// In en, this message translates to:
  /// **'{value} • {secondValue} km away'**
  String kmAwayValue(String value, String secondValue);

  /// Application message: kmAwayValueLabel
  ///
  /// In en, this message translates to:
  /// **'{value} km away'**
  String kmAwayValueLabel(String value);

  /// Application message: kmValue
  ///
  /// In en, this message translates to:
  /// **' {value}km'**
  String kmValue(String value);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lastLocationIsMoreThanAMinuteOld.
  ///
  /// In en, this message translates to:
  /// **'Last location is more than a minute old'**
  String get lastLocationIsMoreThanAMinuteOld;

  /// No description provided for @lateCancellation.
  ///
  /// In en, this message translates to:
  /// **'Late cancellation'**
  String get lateCancellation;

  /// No description provided for @lateCancellationFee.
  ///
  /// In en, this message translates to:
  /// **'Late cancellation fee'**
  String get lateCancellationFee;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @leaveACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment (optional)'**
  String get leaveACommentOptional;

  /// No description provided for @leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Leave the number empty to keep a clearly marked placeholder.'**
  String get leaveTheNumberEmptyToKeepAClearlyMarkedPlaceholder;

  /// No description provided for @licenseExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'license_expires_on'**
  String get licenseExpiresOn;

  /// No description provided for @licenseExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'License expiry date'**
  String get licenseExpiryDate;

  /// No description provided for @licenseImageSelected.
  ///
  /// In en, this message translates to:
  /// **'License image selected'**
  String get licenseImageSelected;

  /// Application message: licenseValue
  ///
  /// In en, this message translates to:
  /// **'License: {value}'**
  String licenseValue(String value);

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @liveDriverTracking.
  ///
  /// In en, this message translates to:
  /// **'Live driver tracking'**
  String get liveDriverTracking;

  /// No description provided for @liveLocationIsActiveForTripMatching.
  ///
  /// In en, this message translates to:
  /// **'Live location is active for trip matching'**
  String get liveLocationIsActiveForTripMatching;

  /// No description provided for @liveLocationIsReconnectingKeepTheAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Live location is reconnecting. Keep the app open.'**
  String get liveLocationIsReconnectingKeepTheAppOpen;

  /// No description provided for @liveMapboxTrackingIsAvailableInTheMobileApp.
  ///
  /// In en, this message translates to:
  /// **'Live Mapbox tracking is available in the mobile app.'**
  String get liveMapboxTrackingIsAvailableInTheMobileApp;

  /// No description provided for @liveOverview.
  ///
  /// In en, this message translates to:
  /// **'Live overview'**
  String get liveOverview;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more…'**
  String get loadingMore;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @loadMoreBookings.
  ///
  /// In en, this message translates to:
  /// **'Load more bookings'**
  String get loadMoreBookings;

  /// No description provided for @loadMorePeople.
  ///
  /// In en, this message translates to:
  /// **'Load more people'**
  String get loadMorePeople;

  /// No description provided for @localContactsAndSos.
  ///
  /// In en, this message translates to:
  /// **'Local contacts and SOS'**
  String get localContactsAndSos;

  /// No description provided for @localEmergencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Local emergency numbers'**
  String get localEmergencyNumbers;

  /// No description provided for @localHistory.
  ///
  /// In en, this message translates to:
  /// **'Local history'**
  String get localHistory;

  /// No description provided for @localRoadsArePreferredFollowRoadSignsAndYourApprovedTodaOrLgu.
  ///
  /// In en, this message translates to:
  /// **'Local roads are preferred. Follow road signs and your approved TODA or LGU route.'**
  String get localRoadsArePreferredFollowRoadSignsAndYourApprovedTodaOrLgu;

  /// No description provided for @locationIsUnavailableRightNowCheckYourSettingsAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable right now. Check your settings and try again.'**
  String get locationIsUnavailableRightNowCheckYourSettingsAndTryAgain;

  /// No description provided for @locationPermissionDeniedEnableItInSettings.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable it in Settings.'**
  String get locationPermissionDeniedEnableItInSettings;

  /// No description provided for @locationPermissionIsNeededToReceiveRides.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to receive rides.'**
  String get locationPermissionIsNeededToReceiveRides;

  /// No description provided for @locationPermissionIsNeededToUseYourCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to use your current position.'**
  String get locationPermissionIsNeededToUseYourCurrentPosition;

  /// No description provided for @locationServicesAreDisabledPleaseEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable GPS.'**
  String get locationServicesAreDisabledPleaseEnableGps;

  /// No description provided for @locationSharingIsAlreadyStopped.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is already stopped.'**
  String get locationSharingIsAlreadyStopped;

  /// No description provided for @locationSharingIsNoLongerAvailableOnThisScreen.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is no longer available on this screen.'**
  String get locationSharingIsNoLongerAvailableOnThisScreen;

  /// No description provided for @locationSharingIsOff.
  ///
  /// In en, this message translates to:
  /// **'Location sharing is off'**
  String get locationSharingIsOff;

  /// No description provided for @locationSharingWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'Location sharing was cancelled.'**
  String get locationSharingWasCancelled;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutLabel;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @lookingForADriver.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver'**
  String get lookingForADriver;

  /// No description provided for @lostPickupCodeReissue.
  ///
  /// In en, this message translates to:
  /// **'Lost pickup code? Reissue'**
  String get lostPickupCodeReissue;

  /// No description provided for @luggageOrBulkyItems.
  ///
  /// In en, this message translates to:
  /// **'Luggage or bulky items'**
  String get luggageOrBulkyItems;

  /// No description provided for @makeItYourOwn.
  ///
  /// In en, this message translates to:
  /// **'Make it your own'**
  String get makeItYourOwn;

  /// No description provided for @manageTourists.
  ///
  /// In en, this message translates to:
  /// **'Manage tourists'**
  String get manageTourists;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get mapView;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @mariaExampleCom.
  ///
  /// In en, this message translates to:
  /// **'maria@example.com'**
  String get mariaExampleCom;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @matchingBlockers.
  ///
  /// In en, this message translates to:
  /// **'Matching blockers'**
  String get matchingBlockers;

  /// No description provided for @matchingIsTemporarilyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Matching is temporarily blocked.'**
  String get matchingIsTemporarilyBlocked;

  /// No description provided for @matchWithTouristsWhoDescribeMobilityOrBoardingNeeds.
  ///
  /// In en, this message translates to:
  /// **'Match with tourists who describe mobility or boarding needs.'**
  String get matchWithTouristsWhoDescribeMobilityOrBoardingNeeds;

  /// No description provided for @maximumCapacityIsCheckedBeforeOfferingTheBooking.
  ///
  /// In en, this message translates to:
  /// **'Maximum capacity is checked before offering the booking.'**
  String get maximumCapacityIsCheckedBeforeOfferingTheBooking;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @min8Characters.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get min8Characters;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 chars'**
  String get min8Chars;

  /// Application message: minsAgoValue
  ///
  /// In en, this message translates to:
  /// **'{value} mins ago'**
  String minsAgoValue(String value);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// Application message: minValue
  ///
  /// In en, this message translates to:
  /// **'{value} · {secondValue} min'**
  String minValue(String value, String secondValue);

  /// Application message: minValueLabel
  ///
  /// In en, this message translates to:
  /// **'{value} min · {secondValue}'**
  String minValueLabel(String value, String secondValue);

  /// Application message: missingValue
  ///
  /// In en, this message translates to:
  /// **'{value} missing'**
  String missingValue(String value);

  /// Application message: modeValue
  ///
  /// In en, this message translates to:
  /// **'{value} mode'**
  String modeValue(String value);

  /// Application message: modeValueLabel
  ///
  /// In en, this message translates to:
  /// **'{value} · {secondValue} mode\n{thirdValue}'**
  String modeValueLabel(String value, String secondValue, String thirdValue);

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @moveTheMapPinOrUseYourCurrentLocationBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Move the map pin or use your current location before saving.'**
  String get moveTheMapPinOrUseYourCurrentLocationBeforeSaving;

  /// Application message: mustBeAtLeastCharactersValue
  ///
  /// In en, this message translates to:
  /// **'{value} must be at least {secondValue} characters'**
  String mustBeAtLeastCharactersValue(String value, String secondValue);

  /// Application message: mustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'{value} must not exceed {secondValue} characters'**
  String mustNotExceedCharactersValue(String value, String secondValue);

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @myData.
  ///
  /// In en, this message translates to:
  /// **'My data'**
  String get myData;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// Application message: nameMustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'Name must not exceed {value} characters'**
  String nameMustNotExceedCharactersValue(String value);

  /// No description provided for @namePlateFranchiseOrServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Name, plate, franchise, or service area'**
  String get namePlateFranchiseOrServiceArea;

  /// No description provided for @nationalEmergencyHotline.
  ///
  /// In en, this message translates to:
  /// **'National emergency hotline'**
  String get nationalEmergencyHotline;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get needsReview;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newRideRequest.
  ///
  /// In en, this message translates to:
  /// **'New ride request'**
  String get newRideRequest;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noActiveBookingOpenTripsToViewYourHistory.
  ///
  /// In en, this message translates to:
  /// **'No active booking. Open Trips to view your history.'**
  String get noActiveBookingOpenTripsToViewYourHistory;

  /// No description provided for @noActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'No active trip'**
  String get noActiveTrip;

  /// No description provided for @noActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'No active trips'**
  String get noActiveTrips;

  /// No description provided for @noArrivalIsAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'No arrival is awaiting confirmation.'**
  String get noArrivalIsAwaitingConfirmation;

  /// No description provided for @noBlockedDrivers.
  ///
  /// In en, this message translates to:
  /// **'No blocked drivers'**
  String get noBlockedDrivers;

  /// No description provided for @noBookingsHereYet.
  ///
  /// In en, this message translates to:
  /// **'No bookings here yet.'**
  String get noBookingsHereYet;

  /// No description provided for @noBookingsInThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No bookings in this category.'**
  String get noBookingsInThisCategory;

  /// No description provided for @noCharge.
  ///
  /// In en, this message translates to:
  /// **'No charge'**
  String get noCharge;

  /// No description provided for @noCompletedBookingsFoundForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No completed bookings found for this period.'**
  String get noCompletedBookingsFoundForThisPeriod;

  /// No description provided for @noCompletedDriverTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed driver trips yet.'**
  String get noCompletedDriverTripsYet;

  /// No description provided for @noConfirmedMoneyMovementYet.
  ///
  /// In en, this message translates to:
  /// **'No confirmed money movement yet.'**
  String get noConfirmedMoneyMovementYet;

  /// No description provided for @noDestinationsSelected.
  ///
  /// In en, this message translates to:
  /// **'No destinations selected'**
  String get noDestinationsSelected;

  /// No description provided for @noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate.
  ///
  /// In en, this message translates to:
  /// **'No distance, waiting or surge additions. Entrance fees and purchases are separate.'**
  String
  get noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate;

  /// No description provided for @noDriverAcceptedDuringThisSearchWindowRetryToOpenAFreshRequest.
  ///
  /// In en, this message translates to:
  /// **'No driver accepted during this search window. Retry to open a fresh request or cancel without charge.'**
  String get noDriverAcceptedDuringThisSearchWindowRetryToOpenAFreshRequest;

  /// No description provided for @noDriversAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'No drivers awaiting review'**
  String get noDriversAwaitingReview;

  /// No description provided for @noDriverYet.
  ///
  /// In en, this message translates to:
  /// **'No driver yet'**
  String get noDriverYet;

  /// No description provided for @noEligibleActiveDrivers.
  ///
  /// In en, this message translates to:
  /// **'No eligible active drivers'**
  String get noEligibleActiveDrivers;

  /// No description provided for @noEndedTripsInThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No ended trips in this period.'**
  String get noEndedTripsInThisPeriod;

  /// No description provided for @noExportRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No export requests yet.'**
  String get noExportRequestsYet;

  /// No description provided for @noLocalRoadRouteWasReturned.
  ///
  /// In en, this message translates to:
  /// **'No local-road route was returned.'**
  String get noLocalRoadRouteWasReturned;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noPastTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No past trips yet'**
  String get noPastTripsYet;

  /// No description provided for @noPendingRequest.
  ///
  /// In en, this message translates to:
  /// **'No pending request'**
  String get noPendingRequest;

  /// No description provided for @noPhotosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No photos available'**
  String get noPhotosAvailable;

  /// No description provided for @noRecentBookings.
  ///
  /// In en, this message translates to:
  /// **'No recent bookings'**
  String get noRecentBookings;

  /// No description provided for @noReviewsFound.
  ///
  /// In en, this message translates to:
  /// **'No reviews found.'**
  String get noReviewsFound;

  /// No description provided for @noShowFee.
  ///
  /// In en, this message translates to:
  /// **'No-show fee'**
  String get noShowFee;

  /// No description provided for @noSpotsFound.
  ///
  /// In en, this message translates to:
  /// **'No spots found'**
  String get noSpotsFound;

  /// No description provided for @noSystemFeedbackFound.
  ///
  /// In en, this message translates to:
  /// **'No system feedback found.'**
  String get noSystemFeedbackFound;

  /// No description provided for @notificationDeliveryFailures.
  ///
  /// In en, this message translates to:
  /// **'Notification delivery failures'**
  String get notificationDeliveryFailures;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noTouristsFound.
  ///
  /// In en, this message translates to:
  /// **'No tourists found'**
  String get noTouristsFound;

  /// No description provided for @noTouristSpotsFound.
  ///
  /// In en, this message translates to:
  /// **'No tourist spots found.'**
  String get noTouristSpotsFound;

  /// No description provided for @notRated.
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get notRated;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @noVerifiedContactNumberIsAvailableForThisTourist.
  ///
  /// In en, this message translates to:
  /// **'No verified contact number is available for this tourist.'**
  String get noVerifiedContactNumberIsAvailableForThisTourist;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @officialEmergencyNumbersFromMunicipalityPortal.
  ///
  /// In en, this message translates to:
  /// **'Official emergency numbers from municipality portal.'**
  String get officialEmergencyNumbersFromMunicipalityPortal;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @offlineConnection.
  ///
  /// In en, this message translates to:
  /// **'Offline connection'**
  String get offlineConnection;

  /// No description provided for @offlineModeShowingSavedDataFromCriticalActionsRequireAConnection.
  ///
  /// In en, this message translates to:
  /// **'Offline mode · showing saved data from {time}. Critical actions require a connection.'**
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnection(
    String time,
  );

  /// Application message: offlineModeShowingSavedDataFromCriticalActionsRequireAConnectionValue
  ///
  /// In en, this message translates to:
  /// **'Offline mode · showing saved data from {value}. Critical actions require a connection.'**
  String offlineModeShowingSavedDataFromCriticalActionsRequireAConnectionValue(
    String value,
  );

  /// No description provided for @offlineSavedInformationMayBeShown.
  ///
  /// In en, this message translates to:
  /// **'Offline · saved information may be shown.'**
  String get offlineSavedInformationMayBeShown;

  /// No description provided for @offThePlannedRouteNavigationIsRecalculatingFollowLegalLocalRoadsAndStop.
  ///
  /// In en, this message translates to:
  /// **'Off the planned route · navigation is recalculating. Follow legal local roads and stop safely if unsure.'**
  String
  get offThePlannedRouteNavigationIsRecalculatingFollowLegalLocalRoadsAndStop;

  /// No description provided for @onePriceForTheBookedRoute.
  ///
  /// In en, this message translates to:
  /// **'One price for the booked route'**
  String get onePriceForTheBookedRoute;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onlinePayment.
  ///
  /// In en, this message translates to:
  /// **'Online payment'**
  String get onlinePayment;

  /// No description provided for @onlinePaymentFailedRetryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Online payment failed — retry available'**
  String get onlinePaymentFailedRetryAvailable;

  /// No description provided for @onlinePaymentNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Online payment not started'**
  String get onlinePaymentNotStarted;

  /// No description provided for @onlinePaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Online payment received'**
  String get onlinePaymentReceived;

  /// No description provided for @onlinePaymentRequiresTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'Online payment requires the configured server.'**
  String get onlinePaymentRequiresTheConfiguredServer;

  /// No description provided for @onlinePaymentsRequireAVerifiedPaymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Online payments require a verified payment provider.'**
  String get onlinePaymentsRequireAVerifiedPaymentProvider;

  /// No description provided for @onlineRefundAwaitingAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Online refund awaiting admin action'**
  String get onlineRefundAwaitingAdminAction;

  /// No description provided for @onlineRefundDue.
  ///
  /// In en, this message translates to:
  /// **'Online refund due'**
  String get onlineRefundDue;

  /// No description provided for @onlyACompletedUnratedTripCanBeReviewed.
  ///
  /// In en, this message translates to:
  /// **'Only a completed, unrated trip can be reviewed.'**
  String get onlyACompletedUnratedTripCanBeReviewed;

  /// No description provided for @onlyAnAcceptedBookingCanStart.
  ///
  /// In en, this message translates to:
  /// **'Only an accepted booking can start.'**
  String get onlyAnAcceptedBookingCanStart;

  /// No description provided for @onlyAnEndedTripWithAnOpenReviewCanBeResolved.
  ///
  /// In en, this message translates to:
  /// **'Only an ended trip with an open review can be resolved.'**
  String get onlyAnEndedTripWithAnOpenReviewCanBeResolved;

  /// No description provided for @onlyAnOngoingTripCanBeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Only an ongoing trip can be completed.'**
  String get onlyAnOngoingTripCanBeCompleted;

  /// No description provided for @onlyAParticipantCanReportAPaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Only a participant can report a payment issue.'**
  String get onlyAParticipantCanReportAPaymentIssue;

  /// No description provided for @onlyAPendingDriverApplicationCanBeResumedFromThisForm.
  ///
  /// In en, this message translates to:
  /// **'Only a pending driver application can be resumed from this form.'**
  String get onlyAPendingDriverApplicationCanBeResumedFromThisForm;

  /// No description provided for @onlyATripParticipantCanEndThisTrip.
  ///
  /// In en, this message translates to:
  /// **'Only a trip participant can end this trip.'**
  String get onlyATripParticipantCanEndThisTrip;

  /// No description provided for @onlyThePayerAndReceiverCanConfirmCash.
  ///
  /// In en, this message translates to:
  /// **'Only the payer and receiver can confirm cash.'**
  String get onlyThePayerAndReceiverCanConfirmCash;

  /// No description provided for @onlyUnvisitedStopsMoveTheOtherParticipantMustApproveBeforeNavigationChanges.
  ///
  /// In en, this message translates to:
  /// **'Only unvisited stops move. The other participant must approve before navigation changes.'**
  String
  get onlyUnvisitedStopsMoveTheOtherParticipantMustApproveBeforeNavigationChanges;

  /// No description provided for @openAPaymentReview.
  ///
  /// In en, this message translates to:
  /// **'Open a payment review'**
  String get openAPaymentReview;

  /// No description provided for @openAppStore.
  ///
  /// In en, this message translates to:
  /// **'Open app store'**
  String get openAppStore;

  /// Application message: openAppToViewThisUpdate
  ///
  /// In en, this message translates to:
  /// **'Open {brandName} to view this update.'**
  String openAppToViewThisUpdate(String brandName);

  /// No description provided for @openDialer.
  ///
  /// In en, this message translates to:
  /// **'Open dialer'**
  String get openDialer;

  /// No description provided for @openDriverSearch.
  ///
  /// In en, this message translates to:
  /// **'Open driver search'**
  String get openDriverSearch;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHours;

  /// Application message: openReviewsValue
  ///
  /// In en, this message translates to:
  /// **'Open reviews: {value}'**
  String openReviewsValue(String value);

  /// No description provided for @openTheMobileAppForTheInteractiveRoute.
  ///
  /// In en, this message translates to:
  /// **'Open the mobile app for the interactive route.'**
  String get openTheMobileAppForTheInteractiveRoute;

  /// No description provided for @openTripMap.
  ///
  /// In en, this message translates to:
  /// **'Open trip map'**
  String get openTripMap;

  /// No description provided for @openTripsToSeeTheLatestBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Open Trips to see the latest booking status.'**
  String get openTripsToSeeTheLatestBookingStatus;

  /// Application message: operationalAlertSNeedReviewValue
  ///
  /// In en, this message translates to:
  /// **'{value} operational alert(s) need review'**
  String operationalAlertSNeedReviewValue(String value);

  /// Application message: operationFailureValue
  ///
  /// In en, this message translates to:
  /// **'Operation failure: {value}'**
  String operationFailureValue(String value);

  /// No description provided for @operationsCentre.
  ///
  /// In en, this message translates to:
  /// **'Operations centre'**
  String get operationsCentre;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @packageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Package not found.'**
  String get packageNotFound;

  /// No description provided for @packageStopsChangedSelectThePackageAgain.
  ///
  /// In en, this message translates to:
  /// **'Package stops changed. Select the package again.'**
  String get packageStopsChangedSelectThePackageAgain;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get paidOnline;

  /// No description provided for @park.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get park;

  /// No description provided for @partiallypaid.
  ///
  /// In en, this message translates to:
  /// **'partiallyPaid'**
  String get partiallypaid;

  /// No description provided for @partiallyRefunded.
  ///
  /// In en, this message translates to:
  /// **'Partially refunded'**
  String get partiallyRefunded;

  /// No description provided for @passengerCapacity.
  ///
  /// In en, this message translates to:
  /// **'Passenger capacity'**
  String get passengerCapacity;

  /// Application message: passengerCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 passenger} other{{count} passengers}}'**
  String passengerCount(int count);

  /// No description provided for @passengerRequirements.
  ///
  /// In en, this message translates to:
  /// **'Passenger requirements'**
  String get passengerRequirements;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// Application message: passengersValue
  ///
  /// In en, this message translates to:
  /// **'{value} passengers'**
  String passengersValue(String value);

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @passwordMustContainAtLeastOneNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMustContainAtLeastOneNumber;

  /// No description provided for @passwordMustContainAtLeastOneUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainAtLeastOneUppercaseLetter;

  /// Application message: passwordMustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'Password must not exceed {value} characters'**
  String passwordMustNotExceedCharactersValue(String value);

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdatedSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in again.'**
  String get passwordUpdatedSignInAgain;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @pauseForAVehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'Pause for a vehicle problem?'**
  String get pauseForAVehicleProblem;

  /// No description provided for @paymentAttention.
  ///
  /// In en, this message translates to:
  /// **'Payment attention'**
  String get paymentAttention;

  /// Application message: paymentDisputedValue
  ///
  /// In en, this message translates to:
  /// **'Payment disputed: {value}'**
  String paymentDisputedValue(String value);

  /// No description provided for @paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr.
  ///
  /// In en, this message translates to:
  /// **'Payment is on hold. An admin must review the case before collection or a cash return.'**
  String get paymentIsOnHoldAnAdminMustReviewTheCaseBeforeCollectionOr;

  /// No description provided for @paymentIsPendingADriverWillOnlyBeRequestedAfterPaymentIsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment is pending. A driver will only be requested after payment is confirmed. Unpaid requests expire after 30 minutes.'**
  String get paymentIsPendingADriverWillOnlyBeRequestedAfterPaymentIsConfirmed;

  /// No description provided for @paymentOnHoldAdminReview.
  ///
  /// In en, this message translates to:
  /// **'Payment on hold · admin review'**
  String get paymentOnHoldAdminReview;

  /// No description provided for @paymentpending.
  ///
  /// In en, this message translates to:
  /// **'paymentPending'**
  String get paymentpending;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPending;

  /// No description provided for @paymentPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'payment_pending'**
  String get paymentPendingLabel;

  /// No description provided for @paymentReview.
  ///
  /// In en, this message translates to:
  /// **'Payment review'**
  String get paymentReview;

  /// No description provided for @paymentReviewPending.
  ///
  /// In en, this message translates to:
  /// **'Payment review pending'**
  String get paymentReviewPending;

  /// No description provided for @paymentStatusCouldNotBeRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Payment status could not be refreshed.'**
  String get paymentStatusCouldNotBeRefreshed;

  /// No description provided for @paymentStatusRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Payment status refreshed.'**
  String get paymentStatusRefreshed;

  /// No description provided for @paymentStatusUnavailableRefreshOrUpdateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Payment status unavailable. Refresh or update the app.'**
  String get paymentStatusUnavailableRefreshOrUpdateTheApp;

  /// No description provided for @paymentVerificationRequiresTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'Payment verification requires the configured server.'**
  String get paymentVerificationRequiresTheConfiguredServer;

  /// No description provided for @paymongo.
  ///
  /// In en, this message translates to:
  /// **'PayMongo'**
  String get paymongo;

  /// No description provided for @paymongoCheckoutReady.
  ///
  /// In en, this message translates to:
  /// **'PayMongo checkout ready'**
  String get paymongoCheckoutReady;

  /// No description provided for @paymongoIsProcessingPayment.
  ///
  /// In en, this message translates to:
  /// **'PayMongo is processing payment'**
  String get paymongoIsProcessingPayment;

  /// No description provided for @paymongoTestModeStatusIsConfirmedByWebhookOrADirectProviderCheck.
  ///
  /// In en, this message translates to:
  /// **'PayMongo test mode · status is confirmed by webhook or a direct provider check.'**
  String get paymongoTestModeStatusIsConfirmedByWebhookOrADirectProviderCheck;

  /// No description provided for @paymongoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'PayMongo unavailable'**
  String get paymongoUnavailable;

  /// No description provided for @payTheFinalAmountAfterTheTripTouristAndDriverMustBothConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay the final amount after the trip. Tourist and driver must both confirm the cash handover.'**
  String get payTheFinalAmountAfterTheTripTouristAndDriverMustBothConfirm;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingRequestsAndDriverCancellationsAreFreeTouristCancellationAfterTheGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Pending requests and driver cancellations are free. Tourist cancellation after the grace period may incur the published fee. A no-show requires verified driver arrival and the full waiting period.'**
  String
  get pendingRequestsAndDriverCancellationsAreFreeTouristCancellationAfterTheGracePeriod;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete'**
  String get permanentlyDelete;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personalInfo;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// No description provided for @photoGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo gallery'**
  String get photoGallery;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @pickupArrivalCanOnlyBeReportedForAnAcceptedBooking.
  ///
  /// In en, this message translates to:
  /// **'Pickup arrival can only be reported for an accepted booking.'**
  String get pickupArrivalCanOnlyBeReportedForAnAcceptedBooking;

  /// No description provided for @pickupArrivalHasAlreadyBeenRecorded.
  ///
  /// In en, this message translates to:
  /// **'Pickup arrival has already been recorded.'**
  String get pickupArrivalHasAlreadyBeenRecorded;

  /// No description provided for @pickupCode.
  ///
  /// In en, this message translates to:
  /// **'Pickup code'**
  String get pickupCode;

  /// No description provided for @pickupCodeVerifiedTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Pickup code verified; trip started.'**
  String get pickupCodeVerifiedTripStarted;

  /// No description provided for @pickupLocationPreview.
  ///
  /// In en, this message translates to:
  /// **'Pickup location preview'**
  String get pickupLocationPreview;

  /// No description provided for @pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get pickupPoint;

  /// Application message: pickupValue
  ///
  /// In en, this message translates to:
  /// **'Pickup: {value}'**
  String pickupValue(String value);

  /// No description provided for @pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Pickup verification is temporarily locked. Please wait and try again.'**
  String get pickupVerificationIsTemporarilyLockedPleaseWaitAndTryAgain;

  /// No description provided for @pickupWait.
  ///
  /// In en, this message translates to:
  /// **'Pickup wait'**
  String get pickupWait;

  /// No description provided for @placeholderTheOwnerMustVerifyAndEnterANumber.
  ///
  /// In en, this message translates to:
  /// **'Placeholder — the owner must verify and enter a number.'**
  String get placeholderTheOwnerMustVerifyAndEnterANumber;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @placesYouSaved.
  ///
  /// In en, this message translates to:
  /// **'Places you saved'**
  String get placesYouSaved;

  /// No description provided for @planYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip'**
  String get planYourTrip;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumber;

  /// No description provided for @plateNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Plate number is required'**
  String get plateNumberIsRequired;

  /// Application message: plateNumberMustNotExceedCharactersValue
  ///
  /// In en, this message translates to:
  /// **'Plate number must not exceed {value} characters'**
  String plateNumberMustNotExceedCharactersValue(String value);

  /// Application message: platformFailureValue
  ///
  /// In en, this message translates to:
  /// **'Platform failure: {value}'**
  String platformFailureValue(String value);

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @pleaseDescribeYourConcernOrSuggestionInDetail.
  ///
  /// In en, this message translates to:
  /// **'Please describe your concern or suggestion in detail...'**
  String get pleaseDescribeYourConcernOrSuggestionInDetail;

  /// No description provided for @pleaseEnterAtLeast20Characters.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 20 characters.'**
  String get pleaseEnterAtLeast20Characters;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @pleaseEnterAValidPlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid plate number'**
  String get pleaseEnterAValidPlateNumber;

  /// No description provided for @pleaseEnterYourStreetOrHouseNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your street or house number'**
  String get pleaseEnterYourStreetOrHouseNumber;

  /// No description provided for @pleaseExplainTheIssueAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Please explain the issue (at least 5 characters).'**
  String get pleaseExplainTheIssueAtLeast5Characters;

  /// No description provided for @pleaseGiveAReasonAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Please give a reason (at least 5 characters).'**
  String get pleaseGiveAReasonAtLeast5Characters;

  /// No description provided for @pleaseProvideDetailsAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Please provide details (at least 5 characters).'**
  String get pleaseProvideDetailsAtLeast5Characters;

  /// No description provided for @pleaseReviewTheCurrentPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Please review the current privacy notice'**
  String get pleaseReviewTheCurrentPrivacyNotice;

  /// No description provided for @pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Please wait five minutes before requesting another pickup code.'**
  String get pleaseWaitFiveMinutesBeforeRequestingAnotherPickupCode;

  /// No description provided for @policyPublishedExistingBookingsAreUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Policy published. Existing bookings are unchanged.'**
  String get policyPublishedExistingBookingsAreUnchanged;

  /// Application message: policyVersionValue
  ///
  /// In en, this message translates to:
  /// **'Policy version {value}'**
  String policyVersionValue(String value);

  /// No description provided for @prepareExport.
  ///
  /// In en, this message translates to:
  /// **'Prepare export'**
  String get prepareExport;

  /// No description provided for @preparePrivateAccountExports.
  ///
  /// In en, this message translates to:
  /// **'Prepare private account exports'**
  String get preparePrivateAccountExports;

  /// No description provided for @preparingDriverRoute.
  ///
  /// In en, this message translates to:
  /// **'Preparing driver route'**
  String get preparingDriverRoute;

  /// No description provided for @preparingRoute.
  ///
  /// In en, this message translates to:
  /// **'Preparing route...'**
  String get preparingRoute;

  /// No description provided for @pressSosToOpenYourPhoneDialerWithTheNationalEmergencyNumber.
  ///
  /// In en, this message translates to:
  /// **'Press SOS to open your phone dialer with the national emergency number.'**
  String get pressSosToOpenYourPhoneDialerWithTheNationalEmergencyNumber;

  /// No description provided for @previewAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Preview announcement'**
  String get previewAnnouncement;

  /// Application message: priceHistoryCurrentVersionValue
  ///
  /// In en, this message translates to:
  /// **'Price history · current version {value}'**
  String priceHistoryCurrentVersionValue(String value);

  /// No description provided for @pricesChangedWhileYouWereEditingReopenThisPageAndReviewTheLatest.
  ///
  /// In en, this message translates to:
  /// **'Prices changed while you were editing. Reopen this page and review the latest rates.'**
  String get pricesChangedWhileYouWereEditingReopenThisPageAndReviewTheLatest;

  /// No description provided for @priceVersion.
  ///
  /// In en, this message translates to:
  /// **'Price version'**
  String get priceVersion;

  /// No description provided for @privacyAndDataUse.
  ///
  /// In en, this message translates to:
  /// **'Privacy and data use'**
  String get privacyAndDataUse;

  /// No description provided for @privacyNoticeAcceptanceIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice acceptance is required.'**
  String get privacyNoticeAcceptanceIsRequired;

  /// No description provided for @privacyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Privacy update'**
  String get privacyUpdate;

  /// No description provided for @profileImagesMustBe5MbOrSmaller.
  ///
  /// In en, this message translates to:
  /// **'Profile images must be 5 MB or smaller.'**
  String get profileImagesMustBe5MbOrSmaller;

  /// No description provided for @profileImagesMustBeJpegOrPngFiles.
  ///
  /// In en, this message translates to:
  /// **'Profile images must be JPEG or PNG files.'**
  String get profileImagesMustBeJpegOrPngFiles;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @profileUpdatedSuccessfullyLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfullyLabel;

  /// No description provided for @proposeANewStopOrder.
  ///
  /// In en, this message translates to:
  /// **'Propose a new stop order'**
  String get proposeANewStopOrder;

  /// Application message: proposedValue
  ///
  /// In en, this message translates to:
  /// **'Proposed: {value}'**
  String proposedValue(String value);

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @publishCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Publish cancellation policy?'**
  String get publishCancellationPolicy;

  /// No description provided for @publishedPolicy.
  ///
  /// In en, this message translates to:
  /// **'Published policy'**
  String get publishedPolicy;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get publishing;

  /// No description provided for @publishPolicy.
  ///
  /// In en, this message translates to:
  /// **'Publish policy'**
  String get publishPolicy;

  /// No description provided for @publishTheseFixedFares.
  ///
  /// In en, this message translates to:
  /// **'Publish these fixed fares?'**
  String get publishTheseFixedFares;

  /// No description provided for @radius130Km.
  ///
  /// In en, this message translates to:
  /// **'Radius (1–30 km)'**
  String get radius130Km;

  /// No description provided for @rateDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate driver'**
  String get rateDriver;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Ratings & feedback'**
  String get ratingsFeedback;

  /// No description provided for @ratingsReviews.
  ///
  /// In en, this message translates to:
  /// **'Ratings & reviews'**
  String get ratingsReviews;

  /// No description provided for @readyForApproval.
  ///
  /// In en, this message translates to:
  /// **'Ready for approval'**
  String get readyForApproval;

  /// No description provided for @readyMadeDaysOut.
  ///
  /// In en, this message translates to:
  /// **'Ready-made days out'**
  String get readyMadeDaysOut;

  /// No description provided for @readyMadeTrips.
  ///
  /// In en, this message translates to:
  /// **'Ready-made trips'**
  String get readyMadeTrips;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Reason (at least 5 characters)'**
  String get reasonAtLeast5Characters;

  /// No description provided for @reasonDetails.
  ///
  /// In en, this message translates to:
  /// **'Reason / details'**
  String get reasonDetails;

  /// No description provided for @reasonForChangingTheOrder.
  ///
  /// In en, this message translates to:
  /// **'Reason for changing the order'**
  String get reasonForChangingTheOrder;

  /// No description provided for @reasonForPolicyChange.
  ///
  /// In en, this message translates to:
  /// **'Reason for policy change'**
  String get reasonForPolicyChange;

  /// No description provided for @reasonForPriceChange.
  ///
  /// In en, this message translates to:
  /// **'Reason for price change'**
  String get reasonForPriceChange;

  /// No description provided for @receiveBookingsEarnMoneyAndShowcaseYourLocalKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Receive bookings, earn money, and showcase your local knowledge.'**
  String get receiveBookingsEarnMoneyAndShowcaseYourLocalKnowledge;

  /// No description provided for @recentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent bookings'**
  String get recentBookings;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh payment status'**
  String get refreshPaymentStatus;

  /// No description provided for @refundCompleted.
  ///
  /// In en, this message translates to:
  /// **'Refund completed'**
  String get refundCompleted;

  /// No description provided for @refundCompletedInPaymongoTestMode.
  ///
  /// In en, this message translates to:
  /// **'Refund completed in PayMongo test mode.'**
  String get refundCompletedInPaymongoTestMode;

  /// No description provided for @refundCompletedInTheTestPaymentEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Refund completed in the test payment environment.'**
  String get refundCompletedInTheTestPaymentEnvironment;

  /// No description provided for @refundDecisionRecorded.
  ///
  /// In en, this message translates to:
  /// **'Refund decision recorded.'**
  String get refundDecisionRecorded;

  /// No description provided for @refunddue.
  ///
  /// In en, this message translates to:
  /// **'refundDue'**
  String get refunddue;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @refundRequired.
  ///
  /// In en, this message translates to:
  /// **'refund_required'**
  String get refundRequired;

  /// No description provided for @refundSentAwaitingPaymongoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Refund sent · awaiting PayMongo confirmation'**
  String get refundSentAwaitingPaymongoConfirmation;

  /// No description provided for @refundUpdateRecorded.
  ///
  /// In en, this message translates to:
  /// **'Refund update recorded.'**
  String get refundUpdateRecorded;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registrationDidNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Registration did not complete.'**
  String get registrationDidNotComplete;

  /// No description provided for @reissueCode.
  ///
  /// In en, this message translates to:
  /// **'Reissue code'**
  String get reissueCode;

  /// No description provided for @reissuePickupCode.
  ///
  /// In en, this message translates to:
  /// **'Reissue pickup code?'**
  String get reissuePickupCode;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject application'**
  String get rejectApplication;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Application message: releaseConfigurationIsIncompleteValue
  ///
  /// In en, this message translates to:
  /// **'Release configuration is incomplete: {value}'**
  String releaseConfigurationIsIncompleteValue(String value);

  /// No description provided for @reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// Application message: reliabilitySeatsValue
  ///
  /// In en, this message translates to:
  /// **'{value}% reliability • {secondValue} seats'**
  String reliabilitySeatsValue(String value, String secondValue);

  /// Application message: reliableValue
  ///
  /// In en, this message translates to:
  /// **'{value}% reliable'**
  String reliableValue(String value);

  /// No description provided for @removedFromYourItinerary.
  ///
  /// In en, this message translates to:
  /// **'Removed from your itinerary'**
  String get removedFromYourItinerary;

  /// No description provided for @removeDuplicateDestinations.
  ///
  /// In en, this message translates to:
  /// **'Remove duplicate destinations.'**
  String get removeDuplicateDestinations;

  /// No description provided for @reopenAttraction.
  ///
  /// In en, this message translates to:
  /// **'Reopen attraction'**
  String get reopenAttraction;

  /// Application message: reopenedValue
  ///
  /// In en, this message translates to:
  /// **'{value} reopened'**
  String reopenedValue(String value);

  /// No description provided for @replacementNeeded.
  ///
  /// In en, this message translates to:
  /// **'Replacement needed'**
  String get replacementNeeded;

  /// No description provided for @replacementpending.
  ///
  /// In en, this message translates to:
  /// **'replacementPending'**
  String get replacementpending;

  /// No description provided for @replacementPending.
  ///
  /// In en, this message translates to:
  /// **'replacement_pending'**
  String get replacementPending;

  /// No description provided for @reportArrivalAtNextStop.
  ///
  /// In en, this message translates to:
  /// **'Report arrival at next stop'**
  String get reportArrivalAtNextStop;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reports & analytics'**
  String get reportsAnalytics;

  /// No description provided for @reportTouristNoShow.
  ///
  /// In en, this message translates to:
  /// **'Report tourist no-show?'**
  String get reportTouristNoShow;

  /// No description provided for @reportTouristNoShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Report tourist no-show'**
  String get reportTouristNoShowLabel;

  /// No description provided for @reportYourVerifiedArrivalAtThePickupPointBeforeStarting.
  ///
  /// In en, this message translates to:
  /// **'Report your verified arrival at the pickup point before starting.'**
  String get reportYourVerifiedArrivalAtThePickupPointBeforeStarting;

  /// No description provided for @requestACopyOfYourAccountAndTripDataSupportPreparesTheExport.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of your account and trip data. Support prepares the export for your account only.'**
  String get requestACopyOfYourAccountAndTripDataSupportPreparesTheExport;

  /// No description provided for @requestADifferentStopOrder.
  ///
  /// In en, this message translates to:
  /// **'Request a different stop order'**
  String get requestADifferentStopOrder;

  /// No description provided for @requestADriverNow.
  ///
  /// In en, this message translates to:
  /// **'Request a driver now'**
  String get requestADriverNow;

  /// No description provided for @requestAnotherDriver.
  ///
  /// In en, this message translates to:
  /// **'Request another driver?'**
  String get requestAnotherDriver;

  /// No description provided for @requestDataExport.
  ///
  /// In en, this message translates to:
  /// **'Request data export'**
  String get requestDataExport;

  /// No description provided for @requestIsNoLongerPending.
  ///
  /// In en, this message translates to:
  /// **'Request is no longer pending'**
  String get requestIsNoLongerPending;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @requestSaved.
  ///
  /// In en, this message translates to:
  /// **'Request saved'**
  String get requestSaved;

  /// No description provided for @requestToSkipThisStop.
  ///
  /// In en, this message translates to:
  /// **'Request to skip this stop'**
  String get requestToSkipThisStop;

  /// Application message: requestToSkipValue
  ///
  /// In en, this message translates to:
  /// **'Request to skip {value}?'**
  String requestToSkipValue(String value);

  /// No description provided for @resetMap.
  ///
  /// In en, this message translates to:
  /// **'Reset map'**
  String get resetMap;

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @resolvePaymentReview.
  ///
  /// In en, this message translates to:
  /// **'Resolve payment review'**
  String get resolvePaymentReview;

  /// No description provided for @resortCaf.
  ///
  /// In en, this message translates to:
  /// **'Resort & Café'**
  String get resortCaf;

  /// No description provided for @respondToCommunityConcerns.
  ///
  /// In en, this message translates to:
  /// **'Respond to community concerns'**
  String get respondToCommunityConcerns;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreTourist.
  ///
  /// In en, this message translates to:
  /// **'Restore tourist?'**
  String get restoreTourist;

  /// No description provided for @resumePayment.
  ///
  /// In en, this message translates to:
  /// **'Resume payment'**
  String get resumePayment;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry connection'**
  String get retryConnection;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying…'**
  String get retrying;

  /// No description provided for @retryStorage.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryStorage;

  /// No description provided for @retypePassword.
  ///
  /// In en, this message translates to:
  /// **'Retype password'**
  String get retypePassword;

  /// No description provided for @revenueOverTime.
  ///
  /// In en, this message translates to:
  /// **'Revenue over time'**
  String get revenueOverTime;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewActiveAndCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Review active and completed trips'**
  String get reviewActiveAndCompletedTrips;

  /// No description provided for @reviewAndPublishFares.
  ///
  /// In en, this message translates to:
  /// **'Review and publish fares'**
  String get reviewAndPublishFares;

  /// No description provided for @reviewAndPublishPolicy.
  ///
  /// In en, this message translates to:
  /// **'Review and publish policy'**
  String get reviewAndPublishPolicy;

  /// No description provided for @reviewCountSummary.
  ///
  /// In en, this message translates to:
  /// **'(128 reviews)'**
  String get reviewCountSummary;

  /// No description provided for @reviewFailuresAndStaleDrivers.
  ///
  /// In en, this message translates to:
  /// **'Review failures and stale drivers'**
  String get reviewFailuresAndStaleDrivers;

  /// No description provided for @reviewFare.
  ///
  /// In en, this message translates to:
  /// **'Review fare'**
  String get reviewFare;

  /// No description provided for @reviewFlaggedForFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Review flagged for follow-up'**
  String get reviewFlaggedForFollowUp;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Review note'**
  String get reviewNote;

  /// No description provided for @reviewPendingDrivers.
  ///
  /// In en, this message translates to:
  /// **'Review pending drivers'**
  String get reviewPendingDrivers;

  /// Application message: reviewResolvedFinalChargeValue
  ///
  /// In en, this message translates to:
  /// **'Review resolved: ₱{value} final charge. {secondValue}'**
  String reviewResolvedFinalChargeValue(String value, String secondValue);

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @reviewYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Review your booking'**
  String get reviewYourBooking;

  /// No description provided for @ride.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get ride;

  /// No description provided for @rideAndBookingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Ride and booking updates'**
  String get rideAndBookingUpdates;

  /// No description provided for @rideUpdates.
  ///
  /// In en, this message translates to:
  /// **'Ride updates'**
  String get rideUpdates;

  /// No description provided for @roadRouteUnavailableCheckYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Road route unavailable. Check your connection and try again.'**
  String get roadRouteUnavailableCheckYourConnectionAndTryAgain;

  /// Application message: routeProgressConfirmedValue
  ///
  /// In en, this message translates to:
  /// **'Route progress · {value}/{secondValue} confirmed'**
  String routeProgressConfirmedValue(String value, String secondValue);

  /// No description provided for @routeReorderApprovalNeeded.
  ///
  /// In en, this message translates to:
  /// **'Route reorder approval needed'**
  String get routeReorderApprovalNeeded;

  /// No description provided for @safeCapacity.
  ///
  /// In en, this message translates to:
  /// **'Safe capacity'**
  String get safeCapacity;

  /// No description provided for @safeDriver.
  ///
  /// In en, this message translates to:
  /// **'Safe driver'**
  String get safeDriver;

  /// No description provided for @safePassengerCapacity.
  ///
  /// In en, this message translates to:
  /// **'Safe passenger capacity'**
  String get safePassengerCapacity;

  /// No description provided for @safetySupport.
  ///
  /// In en, this message translates to:
  /// **'Safety & support'**
  String get safetySupport;

  /// No description provided for @sanPedro.
  ///
  /// In en, this message translates to:
  /// **'San pedro'**
  String get sanPedro;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveDecision.
  ///
  /// In en, this message translates to:
  /// **'Save decision'**
  String get saveDecision;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @savedTripDataCouldNotBeReadBookingChangesArePausedToProtect.
  ///
  /// In en, this message translates to:
  /// **'Saved trip data could not be read. Booking changes are paused to protect your records. Retry storage or restart the app.'**
  String get savedTripDataCouldNotBeReadBookingChangesArePausedToProtect;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @savePlacesYouLove.
  ///
  /// In en, this message translates to:
  /// **'Save places you love'**
  String get savePlacesYouLove;

  /// No description provided for @saveReviewWithoutApproval.
  ///
  /// In en, this message translates to:
  /// **'Save review without approval'**
  String get saveReviewWithoutApproval;

  /// No description provided for @saveSpot.
  ///
  /// In en, this message translates to:
  /// **'Save spot'**
  String get saveSpot;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @savingBooking.
  ///
  /// In en, this message translates to:
  /// **'Saving booking…'**
  String get savingBooking;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get scheduledFor;

  /// No description provided for @scheduledJobFailures.
  ///
  /// In en, this message translates to:
  /// **'Scheduled job failures'**
  String get scheduledJobFailures;

  /// No description provided for @scheduledPickup.
  ///
  /// In en, this message translates to:
  /// **'Scheduled pickup'**
  String get scheduledPickup;

  /// No description provided for @schedulePickupAtLeast1HourFromNow.
  ///
  /// In en, this message translates to:
  /// **'Schedule pickup at least 1 hour from now.'**
  String get schedulePickupAtLeast1HourFromNow;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get searchAgain;

  /// No description provided for @searchDrivers.
  ///
  /// In en, this message translates to:
  /// **'Search drivers'**
  String get searchDrivers;

  /// No description provided for @searchSpots.
  ///
  /// In en, this message translates to:
  /// **'Search spots...'**
  String get searchSpots;

  /// No description provided for @searchWindowEnded.
  ///
  /// In en, this message translates to:
  /// **'Search window ended'**
  String get searchWindowEnded;

  /// No description provided for @secureYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Secure your account'**
  String get secureYourAccount;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @seeYourDailyTripSummary.
  ///
  /// In en, this message translates to:
  /// **'See your daily trip summary'**
  String get seeYourDailyTripSummary;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select address'**
  String get selectAddress;

  /// No description provided for @selectARatingBetween1And5.
  ///
  /// In en, this message translates to:
  /// **'Select a rating between 1 and 5.'**
  String get selectARatingBetween1And5;

  /// No description provided for @selectAtLeastOneDestinationFirst.
  ///
  /// In en, this message translates to:
  /// **'Select at least one destination first.'**
  String get selectAtLeastOneDestinationFirst;

  /// No description provided for @selectBetween1And12Destinations.
  ///
  /// In en, this message translates to:
  /// **'Select between 1 and 12 destinations.'**
  String get selectBetween1And12Destinations;

  /// No description provided for @selectedStop.
  ///
  /// In en, this message translates to:
  /// **'Selected stop'**
  String get selectedStop;

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get selectExpiryDate;

  /// No description provided for @sendAnAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Send an announcement'**
  String get sendAnAnnouncement;

  /// No description provided for @sendAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Send announcement'**
  String get sendAnnouncement;

  /// No description provided for @sendASupportMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a support message'**
  String get sendASupportMessage;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendProposal.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get sendProposal;

  /// No description provided for @sendRefundRequestToPaymongo.
  ///
  /// In en, this message translates to:
  /// **'Send refund request to PayMongo'**
  String get sendRefundRequestToPaymongo;

  /// No description provided for @sendRefundToPaymongo.
  ///
  /// In en, this message translates to:
  /// **'Send refund to PayMongo?'**
  String get sendRefundToPaymongo;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @serverSetupIsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Server setup is incomplete.'**
  String get serverSetupIsIncomplete;

  /// No description provided for @serverSetupIsIncompleteAddTheSupabaseBuildConfigurationBeforeSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Server setup is incomplete. Add the Supabase build configuration before signing in.'**
  String
  get serverSetupIsIncompleteAddTheSupabaseBuildConfigurationBeforeSigningIn;

  /// No description provided for @serverSetupIsIncompleteFeedbackWasNotSent.
  ///
  /// In en, this message translates to:
  /// **'Server setup is incomplete. Feedback was not sent.'**
  String get serverSetupIsIncompleteFeedbackWasNotSent;

  /// No description provided for @serverSetupIsIncompleteNothingWasSent.
  ///
  /// In en, this message translates to:
  /// **'Server setup is incomplete. Nothing was sent.'**
  String get serverSetupIsIncompleteNothingWasSent;

  /// No description provided for @serverSetupIsIncompleteTheAttractionWasNotSaved.
  ///
  /// In en, this message translates to:
  /// **'Server setup is incomplete. The attraction was not saved.'**
  String get serverSetupIsIncompleteTheAttractionWasNotSaved;

  /// Application message: serviceAreaValue
  ///
  /// In en, this message translates to:
  /// **'Service area: {value} '**
  String serviceAreaValue(String value);

  /// No description provided for @serviceHealth.
  ///
  /// In en, this message translates to:
  /// **'Service health'**
  String get serviceHealth;

  /// No description provided for @sessionChanged.
  ///
  /// In en, this message translates to:
  /// **'Session changed.'**
  String get sessionChanged;

  /// No description provided for @setAFlatCustomTourFareAndAFixedFareForEachPackage.
  ///
  /// In en, this message translates to:
  /// **'Set a flat custom-tour fare and a fixed fare for each package. No automatic per-stop, distance, waiting-time or surge additions. Entrance fees are paid separately.'**
  String get setAFlatCustomTourFareAndAFixedFareForEachPackage;

  /// No description provided for @shareAnUpdateWithDriversOrTourists.
  ///
  /// In en, this message translates to:
  /// **'Share an update with drivers or tourists'**
  String get shareAnUpdateWithDriversOrTourists;

  /// No description provided for @shareThisCodeOnlyWhenYouAreOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Share this code only when you are on board'**
  String get shareThisCodeOnlyWhenYouAreOnBoard;

  /// No description provided for @sharingLocation.
  ///
  /// In en, this message translates to:
  /// **'Sharing location'**
  String get sharingLocation;

  /// Application message: showValue
  ///
  /// In en, this message translates to:
  /// **'Show {value}'**
  String showValue(String value);

  /// No description provided for @signInAfterConfirmingYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in after confirming your email.'**
  String get signInAfterConfirmingYourEmail;

  /// No description provided for @signInBeforeSendingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Sign in before sending feedback.'**
  String get signInBeforeSendingFeedback;

  /// No description provided for @signInFirst.
  ///
  /// In en, this message translates to:
  /// **'Sign in first.'**
  String get signInFirst;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @someInformationCouldNotRefreshPreviouslyLoadedDataIsShownReconnectAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Some information could not refresh. Previously loaded data is shown; reconnect and retry.'**
  String
  get someInformationCouldNotRefreshPreviouslyLoadedDataIsShownReconnectAndRetry;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @spotName.
  ///
  /// In en, this message translates to:
  /// **'Spot name'**
  String get spotName;

  /// No description provided for @spots.
  ///
  /// In en, this message translates to:
  /// **'spots'**
  String get spots;

  /// No description provided for @staleOnlineDrivers.
  ///
  /// In en, this message translates to:
  /// **'Stale online drivers'**
  String get staleOnlineDrivers;

  /// No description provided for @startNewSearch.
  ///
  /// In en, this message translates to:
  /// **'Start new search'**
  String get startNewSearch;

  /// Application message: statusValue
  ///
  /// In en, this message translates to:
  /// **'{value} status'**
  String statusValue(String value);

  /// No description provided for @stillToPay.
  ///
  /// In en, this message translates to:
  /// **'Still to pay'**
  String get stillToPay;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopAtASafePlaceFirstTheTripWillEndImmediatelyPaymentWill.
  ///
  /// In en, this message translates to:
  /// **'Stop at a safe place first. The trip will end immediately. Payment will be held for admin review; neither party can demand the full fare automatically. Describe what happened (changed plans, breakdown, safety concern, closed venue, etc.).'**
  String get stopAtASafePlaceFirstTheTripWillEndImmediatelyPaymentWill;

  /// Application message: stopCustomTourValue
  ///
  /// In en, this message translates to:
  /// **'{value} stop custom tour'**
  String stopCustomTourValue(String value);

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'stops'**
  String get stops;

  /// No description provided for @stopsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Stops included'**
  String get stopsIncluded;

  /// No description provided for @stopSkipApprovalNeeded.
  ///
  /// In en, this message translates to:
  /// **'Stop-skip approval needed'**
  String get stopSkipApprovalNeeded;

  /// No description provided for @stopSomewhereSafeFirstYourCurrentGpsLocationAndExplanationWillBeRecorded.
  ///
  /// In en, this message translates to:
  /// **'Stop somewhere safe first. Your current GPS location and explanation will be recorded. The tourist can wait or end the tour for payment review.'**
  String
  get stopSomewhereSafeFirstYourCurrentGpsLocationAndExplanationWillBeRecorded;

  /// Application message: stopsValue
  ///
  /// In en, this message translates to:
  /// **'{value} stops'**
  String stopsValue(String value);

  /// Application message: stopsValueLabel
  ///
  /// In en, this message translates to:
  /// **'{value} stops • ₱{secondValue}'**
  String stopsValueLabel(String value, String secondValue);

  /// No description provided for @stopTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stop temporarily unavailable'**
  String get stopTemporarilyUnavailable;

  /// Application message: stopValue
  ///
  /// In en, this message translates to:
  /// **'Stop: {value}'**
  String stopValue(String value);

  /// No description provided for @storageIsUnavailableRetryStorageBeforeMakingChanges.
  ///
  /// In en, this message translates to:
  /// **'Storage is unavailable. Retry storage before making changes.'**
  String get storageIsUnavailableRetryStorageBeforeMakingChanges;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store unavailable'**
  String get storeUnavailable;

  /// No description provided for @streetHouseNo.
  ///
  /// In en, this message translates to:
  /// **'Street/house no.'**
  String get streetHouseNo;

  /// No description provided for @streetNameBuildingHouseNo.
  ///
  /// In en, this message translates to:
  /// **'Street name, building, house no.'**
  String get streetNameBuildingHouseNo;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitApplication;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @submittedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submitted documents'**
  String get submittedDocuments;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @supportSettings.
  ///
  /// In en, this message translates to:
  /// **'Support & settings'**
  String get supportSettings;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @suspendDriver.
  ///
  /// In en, this message translates to:
  /// **'Suspend driver'**
  String get suspendDriver;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @suspendTourist.
  ///
  /// In en, this message translates to:
  /// **'Suspend tourist?'**
  String get suspendTourist;

  /// No description provided for @suspendTouristLabel.
  ///
  /// In en, this message translates to:
  /// **'Suspend tourist'**
  String get suspendTouristLabel;

  /// Application message: suspendValue
  ///
  /// In en, this message translates to:
  /// **'Suspend {value}'**
  String suspendValue(String value);

  /// No description provided for @systemActionsAreUnavailableHere.
  ///
  /// In en, this message translates to:
  /// **'System actions are unavailable here.'**
  String get systemActionsAreUnavailableHere;

  /// No description provided for @systemFeedback.
  ///
  /// In en, this message translates to:
  /// **'System feedback'**
  String get systemFeedback;

  /// No description provided for @tapTheHeartOnAnyTouristSpotToKeepItHere.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any tourist spot to keep it here.'**
  String get tapTheHeartOnAnyTouristSpotToKeepItHere;

  /// No description provided for @tellUsWhatToImprove.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to improve'**
  String get tellUsWhatToImprove;

  /// No description provided for @temporarilyCloseAttraction.
  ///
  /// In en, this message translates to:
  /// **'Temporarily close attraction'**
  String get temporarilyCloseAttraction;

  /// No description provided for @temporarilyClosed.
  ///
  /// In en, this message translates to:
  /// **'Temporarily closed'**
  String get temporarilyClosed;

  /// Application message: temporarilyClosedValue
  ///
  /// In en, this message translates to:
  /// **'{value} temporarily closed'**
  String temporarilyClosedValue(String value);

  /// No description provided for @thankYouForYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForYourFeedback;

  /// No description provided for @thatPickupCodeIsIncorrectOrTemporarilyLockedAfterRepeatedAttempts.
  ///
  /// In en, this message translates to:
  /// **'That pickup code is incorrect or temporarily locked after repeated attempts.'**
  String get thatPickupCodeIsIncorrectOrTemporarilyLockedAfterRepeatedAttempts;

  /// No description provided for @theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'The agreed tour fare is fixed; there is no surge pricing. Pending requests and driver cancellations are free. After a driver accepts, the tourist has a short grace period, then the published cancellation fee may apply. After pickup, end safely and an admin reviews the completed service and evidence. Entrance fees and personal purchases remain separate.'**
  String get theAgreedTourFareIsFixedThereIsNoSurgePricingPendingRequests;

  /// No description provided for @theAssignedDriverIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assigned driver is unavailable.'**
  String get theAssignedDriverIsUnavailable;

  /// No description provided for @theBookingWillEndWithoutACancellationChargeIfAnOnlinePaymentWas.
  ///
  /// In en, this message translates to:
  /// **'The booking will end without a cancellation charge. If an online payment was already received, it will be marked for refund.'**
  String get theBookingWillEndWithoutACancellationChargeIfAnOnlinePaymentWas;

  /// No description provided for @theCheckoutAddressCouldNotBeVerifiedRefreshThisBookingBeforePaying.
  ///
  /// In en, this message translates to:
  /// **'The checkout address could not be verified. Refresh this booking before paying.'**
  String get theCheckoutAddressCouldNotBeVerifiedRefreshThisBookingBeforePaying;

  /// No description provided for @theDriverMovedAwayFromThePlannedRouteAndNavigationWasRecalculatedLive.
  ///
  /// In en, this message translates to:
  /// **'The driver moved away from the planned route and navigation was recalculated. Live tracking remains active.'**
  String
  get theDriverMovedAwayFromThePlannedRouteAndNavigationWasRecalculatedLive;

  /// No description provided for @theDriverReportedAVehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'The driver reported a vehicle problem.'**
  String get theDriverReportedAVehicleProblem;

  /// No description provided for @theDriverWillFollowTheSelectedPinConfirmThatItMatchesTheAddress.
  ///
  /// In en, this message translates to:
  /// **'The driver will follow the selected pin. Confirm that it matches the address you entered.'**
  String get theDriverWillFollowTheSelectedPinConfirmThatItMatchesTheAddress;

  /// No description provided for @theFinalChargeMustBeBetweenZeroAndTheAgreedFare.
  ///
  /// In en, this message translates to:
  /// **'The final charge must be between zero and the agreed fare.'**
  String get theFinalChargeMustBeBetweenZeroAndTheAgreedFare;

  /// No description provided for @theFinalChargeMustBeSettledBeforeConfirmingCash.
  ///
  /// In en, this message translates to:
  /// **'The final charge must be settled before confirming cash.'**
  String get theFinalChargeMustBeSettledBeforeConfirmingCash;

  /// No description provided for @theFinancialRecordRequiresTheConfiguredServer.
  ///
  /// In en, this message translates to:
  /// **'The financial record requires the configured server.'**
  String get theFinancialRecordRequiresTheConfiguredServer;

  /// No description provided for @theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd.
  ///
  /// In en, this message translates to:
  /// **'The GPS position is stale or invalid. Wait for a fresh signal and retry.'**
  String get theGpsPositionIsStaleOrInvalidWaitForAFreshSignalAnd;

  /// No description provided for @theInteractiveOperationsMapIsAvailableInTheMobileApp.
  ///
  /// In en, this message translates to:
  /// **'The interactive operations map is available in the mobile app.'**
  String get theInteractiveOperationsMapIsAvailableInTheMobileApp;

  /// No description provided for @theOtherParticipantMustApproveIfApprovedFinalPaymentWillBeHeldFor.
  ///
  /// In en, this message translates to:
  /// **'The other participant must approve. If approved, final payment will be held for a fair admin review because the delivered route changed.'**
  String get theOtherParticipantMustApproveIfApprovedFinalPaymentWillBeHeldFor;

  /// No description provided for @theOwnerMustVerifyLocalAgencyNumbersBeforeEnablingCalls.
  ///
  /// In en, this message translates to:
  /// **'The owner must verify local agency numbers before enabling calls.'**
  String get theOwnerMustVerifyLocalAgencyNumbersBeforeEnablingCalls;

  /// No description provided for @thePickupPinIsOutsideTheServiceAreaChooseANearbyPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'The pickup pin is outside the service area. Choose a nearby pickup point.'**
  String get thePickupPinIsOutsideTheServiceAreaChooseANearbyPickupPoint;

  /// No description provided for @thePickupPinIsOutsideTheServiceAreaChooseAnotherPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'The pickup pin is outside the service area. Choose another pickup point.'**
  String get thePickupPinIsOutsideTheServiceAreaChooseAnotherPickupPoint;

  /// No description provided for @thePickupWaitingPeriodHasNotFinished.
  ///
  /// In en, this message translates to:
  /// **'The pickup waiting period has not finished.'**
  String get thePickupWaitingPeriodHasNotFinished;

  /// No description provided for @thePolicyChangedWhileYouWereEditingReopenThisPage.
  ///
  /// In en, this message translates to:
  /// **'The policy changed while you were editing. Reopen this page.'**
  String get thePolicyChangedWhileYouWereEditingReopenThisPage;

  /// No description provided for @thePriceChangedReviewTheUpdatedFareAndConfirmAgain.
  ///
  /// In en, this message translates to:
  /// **'The price changed. Review the updated fare and confirm again.'**
  String get thePriceChangedReviewTheUpdatedFareAndConfirmAgain;

  /// No description provided for @thereAreNoRegisteredTouristsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no registered tourists yet.'**
  String get thereAreNoRegisteredTouristsYet;

  /// No description provided for @thereIsNoOpenReviewOnThisBooking.
  ///
  /// In en, this message translates to:
  /// **'There is no open review on this booking.'**
  String get thereIsNoOpenReviewOnThisBooking;

  /// No description provided for @thereIsNoOutstandingAmountToConfirm.
  ///
  /// In en, this message translates to:
  /// **'There is no outstanding amount to confirm.'**
  String get thereIsNoOutstandingAmountToConfirm;

  /// No description provided for @theRideRequestIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The ride request is no longer available.'**
  String get theRideRequestIsNoLongerAvailable;

  /// No description provided for @theServerIsNotConfiguredOnThisBuildAddTheSupabaseUrlAnd.
  ///
  /// In en, this message translates to:
  /// **'The server is not configured on this build. Add the Supabase URL and publishable key, then rebuild the app.'**
  String get theServerIsNotConfiguredOnThisBuildAddTheSupabaseUrlAnd;

  /// No description provided for @theTouristMustConfirmAllBookedStopsUseEndTourEarlyForAn.
  ///
  /// In en, this message translates to:
  /// **'The tourist must confirm all booked stops. Use End tour early for an incomplete route.'**
  String get theTouristMustConfirmAllBookedStopsUseEndTourEarlyForAn;

  /// No description provided for @thisAccountBelongsToThePortal.
  ///
  /// In en, this message translates to:
  /// **'This account belongs to the {role} portal.'**
  String thisAccountBelongsToThePortal(String role);

  /// Application message: thisAccountBelongsToThePortalValue
  ///
  /// In en, this message translates to:
  /// **'This account belongs to the {value} portal.'**
  String thisAccountBelongsToThePortalValue(String value);

  /// No description provided for @thisAccountCannotSignIn.
  ///
  /// In en, this message translates to:
  /// **'This account cannot sign in.'**
  String get thisAccountCannotSignIn;

  /// No description provided for @thisAccountHasAnInvalidRole.
  ///
  /// In en, this message translates to:
  /// **'This account has an invalid role.'**
  String get thisAccountHasAnInvalidRole;

  /// No description provided for @thisAccountIsNotCurrentlyAllowedToSignIn.
  ///
  /// In en, this message translates to:
  /// **'This account is not currently allowed to sign in.'**
  String get thisAccountIsNotCurrentlyAllowedToSignIn;

  /// No description provided for @thisAccountIsStillAwaitingAdministratorApproval.
  ///
  /// In en, this message translates to:
  /// **'This account is still awaiting administrator approval.'**
  String get thisAccountIsStillAwaitingAdministratorApproval;

  /// No description provided for @thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd.
  ///
  /// In en, this message translates to:
  /// **'This action could not be completed. Your existing records are preserved. Refresh and try again.'**
  String
  get thisActionCouldNotBeCompletedYourExistingRecordsArePreservedRefreshAnd;

  /// No description provided for @thisAttractionBelongsToATourPackageHideItInsteadOfDeletingIt.
  ///
  /// In en, this message translates to:
  /// **'This attraction belongs to a tour package. Hide it instead of deleting it.'**
  String get thisAttractionBelongsToATourPackageHideItInsteadOfDeletingIt;

  /// No description provided for @thisAttractionIsInAnActiveBookingHideItForNewTripsInstead.
  ///
  /// In en, this message translates to:
  /// **'This attraction is in an active booking. Hide it for new trips instead.'**
  String get thisAttractionIsInAnActiveBookingHideItForNewTripsInstead;

  /// No description provided for @thisAttractionIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This attraction is no longer available.'**
  String get thisAttractionIsNoLongerAvailable;

  /// No description provided for @thisBookingBelongsToAnotherTourist.
  ///
  /// In en, this message translates to:
  /// **'This booking belongs to another tourist.'**
  String get thisBookingBelongsToAnotherTourist;

  /// No description provided for @thisBookingCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'This booking could not be found.'**
  String get thisBookingCouldNotBeFound;

  /// No description provided for @thisBookingIsAlreadyUnderReviewAddYourStatementToTheCase.
  ///
  /// In en, this message translates to:
  /// **'This booking is already under review. Add your statement to the case.'**
  String get thisBookingIsAlreadyUnderReviewAddYourStatementToTheCase;

  /// No description provided for @thisBookingIsAssignedToAnotherDriver.
  ///
  /// In en, this message translates to:
  /// **'This booking is assigned to another driver.'**
  String get thisBookingIsAssignedToAnotherDriver;

  /// No description provided for @thisBookingRequestIsNotReadyToRetry.
  ///
  /// In en, this message translates to:
  /// **'This booking request is not ready to retry.'**
  String get thisBookingRequestIsNotReadyToRetry;

  /// No description provided for @thisCancellationIsCurrentlyFreeGiveTheRealReasonSoTheEventCan.
  ///
  /// In en, this message translates to:
  /// **'This cancellation is currently free. Give the real reason so the event can be audited.'**
  String get thisCancellationIsCurrentlyFreeGiveTheRealReasonSoTheEventCan;

  /// No description provided for @thisCompletesTheRefundWorkflowForThePaymongoTestTransactionRecordsTheResult.
  ///
  /// In en, this message translates to:
  /// **'This completes the refund workflow for the PayMongo test transaction, records the result, and notifies the tourist. Enter the reason for the refund.'**
  String
  get thisCompletesTheRefundWorkflowForThePaymongoTestTransactionRecordsTheResult;

  /// No description provided for @thisDriverAccountIsStillAwaitingAdministratorApproval.
  ///
  /// In en, this message translates to:
  /// **'This driver account is still awaiting administrator approval.'**
  String get thisDriverAccountIsStillAwaitingAdministratorApproval;

  /// No description provided for @thisField.
  ///
  /// In en, this message translates to:
  /// **'This field'**
  String get thisField;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisOpensYourPhoneDialerConfirmTheNumberBeforeCalling.
  ///
  /// In en, this message translates to:
  /// **'This opens your phone dialer. Confirm the number before calling.'**
  String get thisOpensYourPhoneDialerConfirmTheNumberBeforeCalling;

  /// No description provided for @thisOpensYourPhoneDialerWith911YouMustPressCallToContact.
  ///
  /// In en, this message translates to:
  /// **'This opens your phone dialer with 911. You must press Call to contact emergency services.'**
  String get thisOpensYourPhoneDialerWith911YouMustPressCallToContact;

  /// No description provided for @thisPackageCannotBeBookedUntilAllStopsAreAvailable.
  ///
  /// In en, this message translates to:
  /// **'This package cannot be booked until all stops are available.'**
  String get thisPackageCannotBeBookedUntilAllStopsAreAvailable;

  /// No description provided for @thisPackageHasAFixedRouteTheStopsAreAlreadySelectedForYou.
  ///
  /// In en, this message translates to:
  /// **'This package has a fixed route. The stops are already selected for you.'**
  String get thisPackageHasAFixedRouteTheStopsAreAlreadySelectedForYou;

  /// No description provided for @thisPackageHasNoPublishedPrice.
  ///
  /// In en, this message translates to:
  /// **'This package has no published price.'**
  String get thisPackageHasNoPublishedPrice;

  /// No description provided for @thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne.
  ///
  /// In en, this message translates to:
  /// **'This password-reset link is invalid or expired. Request a new one.'**
  String get thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne;

  /// No description provided for @thisPickupPinIsOutsideTheServiceAreaMoveThePinCloserTo.
  ///
  /// In en, this message translates to:
  /// **'This pickup pin is outside the service area. Move the pin closer to the service centre.'**
  String get thisPickupPinIsOutsideTheServiceAreaMoveThePinCloserTo;

  /// No description provided for @thisRemovesYourLoginProfileDetailsDocumentsAndAvatarsRetainedTripAndFinancial.
  ///
  /// In en, this message translates to:
  /// **'This removes your login, profile details, documents and avatars. Retained trip and financial records are disconnected from your identity. Finish or cancel active bookings first. Type DELETE to confirm.'**
  String
  get thisRemovesYourLoginProfileDetailsDocumentsAndAvatarsRetainedTripAndFinancial;

  /// No description provided for @thisRequestAlreadyExistsRefreshYourTripsBeforeTryingAgain.
  ///
  /// In en, this message translates to:
  /// **'This request already exists. Refresh your trips before trying again.'**
  String get thisRequestAlreadyExistsRefreshYourTripsBeforeTryingAgain;

  /// No description provided for @thisRequestIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get thisRequestIsNoLongerAvailable;

  /// No description provided for @thisSendsTheExactAmountToPaymongoAndRecordsOnlyTheProviderResult.
  ///
  /// In en, this message translates to:
  /// **'This sends the exact amount to PayMongo and records only the provider result. PayMongo currently limits actual refunds to live transactions, so a test-mode rejection will remain clearly marked as not refunded. Enter the decision reason.'**
  String get thisSendsTheExactAmountToPaymongoAndRecordsOnlyTheProviderResult;

  /// No description provided for @thisTouristAccountCannotBookRightNowContactTheAdministrator.
  ///
  /// In en, this message translates to:
  /// **'This tourist account cannot book right now. Contact the administrator.'**
  String get thisTouristAccountCannotBookRightNowContactTheAdministrator;

  /// No description provided for @thisTouristAccountIsCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This tourist account is currently unavailable.'**
  String get thisTouristAccountIsCurrentlyUnavailable;

  /// No description provided for @thisTripCouldNotBeFoundOrHasBeenRemoved.
  ///
  /// In en, this message translates to:
  /// **'This trip could not be found or has been removed.'**
  String get thisTripCouldNotBeFoundOrHasBeenRemoved;

  /// No description provided for @thisTripHasAlreadyEnded.
  ///
  /// In en, this message translates to:
  /// **'This trip has already ended.'**
  String get thisTripHasAlreadyEnded;

  /// No description provided for @thisTripIsNotInProgress.
  ///
  /// In en, this message translates to:
  /// **'This trip is not in progress.'**
  String get thisTripIsNotInProgress;

  /// No description provided for @thisTripUsesANewerStatusUpdateTheAppOrContactSupportBefore.
  ///
  /// In en, this message translates to:
  /// **'This trip uses a newer status. Update the app or contact support before making changes.'**
  String get thisTripUsesANewerStatusUpdateTheAppOrContactSupportBefore;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// Application message: threeLineSummary
  ///
  /// In en, this message translates to:
  /// **'{value} · {secondValue}\n{thirdValue}'**
  String threeLineSummary(String value, String secondValue, String thirdValue);

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @tipsReminders.
  ///
  /// In en, this message translates to:
  /// **'Tips & reminders'**
  String get tipsReminders;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @totalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total bookings'**
  String get totalBookings;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total fare'**
  String get totalFare;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get totalRevenue;

  /// No description provided for @tourEndedEarlyPaymentHeldForReview.
  ///
  /// In en, this message translates to:
  /// **'Tour ended early; payment held for review'**
  String get tourEndedEarlyPaymentHeldForReview;

  /// No description provided for @tourist.
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get tourist;

  /// No description provided for @touristAccountActivated.
  ///
  /// In en, this message translates to:
  /// **'Tourist account activated'**
  String get touristAccountActivated;

  /// No description provided for @touristAccounts.
  ///
  /// In en, this message translates to:
  /// **'Tourist accounts'**
  String get touristAccounts;

  /// No description provided for @touristAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Tourist account suspended'**
  String get touristAccountSuspended;

  /// No description provided for @touristAndDriverPolicyTerms.
  ///
  /// In en, this message translates to:
  /// **'Tourist and driver policy terms'**
  String get touristAndDriverPolicyTerms;

  /// Application message: touristConfirmedStopValue
  ///
  /// In en, this message translates to:
  /// **'Tourist confirmed stop {value}.'**
  String touristConfirmedStopValue(String value);

  /// No description provided for @touristNoShowAfterVerifiedPickupWait.
  ///
  /// In en, this message translates to:
  /// **'Tourist no-show after verified pickup wait.'**
  String get touristNoShowAfterVerifiedPickupWait;

  /// No description provided for @touristReportedAsANoShowAfterTheVerifiedWaitingPeriodPublishedNo.
  ///
  /// In en, this message translates to:
  /// **'Tourist reported as a no-show after the verified waiting period. Published no-show fee applied.'**
  String get touristReportedAsANoShowAfterTheVerifiedWaitingPeriodPublishedNo;

  /// No description provided for @tourists.
  ///
  /// In en, this message translates to:
  /// **'Tourists'**
  String get tourists;

  /// No description provided for @touristsAndDrivers.
  ///
  /// In en, this message translates to:
  /// **'Tourists and drivers'**
  String get touristsAndDrivers;

  /// No description provided for @touristSpot.
  ///
  /// In en, this message translates to:
  /// **'Tourist spot'**
  String get touristSpot;

  /// No description provided for @touristSpotCreated.
  ///
  /// In en, this message translates to:
  /// **'Tourist spot created'**
  String get touristSpotCreated;

  /// No description provided for @touristSpotIssue.
  ///
  /// In en, this message translates to:
  /// **'Tourist spot issue'**
  String get touristSpotIssue;

  /// No description provided for @touristSpots.
  ///
  /// In en, this message translates to:
  /// **'Tourist spots'**
  String get touristSpots;

  /// No description provided for @touristSpotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tourist spot updated'**
  String get touristSpotUpdated;

  /// Application message: touristVisibilityValue
  ///
  /// In en, this message translates to:
  /// **'{value} tourist visibility'**
  String touristVisibilityValue(String value);

  /// No description provided for @tourPackage.
  ///
  /// In en, this message translates to:
  /// **'Tour package'**
  String get tourPackage;

  /// No description provided for @tourPackages.
  ///
  /// In en, this message translates to:
  /// **'Tour packages'**
  String get tourPackages;

  /// No description provided for @tourScheduled.
  ///
  /// In en, this message translates to:
  /// **'Tour scheduled'**
  String get tourScheduled;

  /// No description provided for @tricycleBooking.
  ///
  /// In en, this message translates to:
  /// **'Tricycle booking'**
  String get tricycleBooking;

  /// No description provided for @trip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip;

  /// No description provided for @tripCompletedFixedFareDueCashNotYetConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Trip completed. Fixed fare due; cash not yet confirmed.'**
  String get tripCompletedFixedFareDueCashNotYetConfirmed;

  /// No description provided for @tripControls.
  ///
  /// In en, this message translates to:
  /// **'Trip controls'**
  String get tripControls;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @tripOngoing.
  ///
  /// In en, this message translates to:
  /// **'Trip ongoing'**
  String get tripOngoing;

  /// Application message: tripPausedOpenTripControlsToChooseWhetherToWaitOrEndSafelyValue
  ///
  /// In en, this message translates to:
  /// **'Trip paused: {value}. Open Trip controls to choose whether to wait or end safely.'**
  String tripPausedOpenTripControlsToChooseWhetherToWaitOrEndSafelyValue(
    String value,
  );

  /// No description provided for @tripPausedVehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'Trip paused · vehicle problem'**
  String get tripPausedVehicleProblem;

  /// No description provided for @tripPayment.
  ///
  /// In en, this message translates to:
  /// **'Trip & payment'**
  String get tripPayment;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// Application message: tripsValue
  ///
  /// In en, this message translates to:
  /// **'Trips: {value}'**
  String tripsValue(String value);

  /// No description provided for @tripUpdates.
  ///
  /// In en, this message translates to:
  /// **'Trip updates'**
  String get tripUpdates;

  /// No description provided for @tryAdjustingYourFiltersOrSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search term.'**
  String get tryAdjustingYourFiltersOrSearchTerm;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @turnByTurnMappingIsAvailableInTheMobileApp.
  ///
  /// In en, this message translates to:
  /// **'Turn-by-turn mapping is available in the mobile app.'**
  String get turnByTurnMappingIsAvailableInTheMobileApp;

  /// No description provided for @turnOnGpsToShareYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Turn on GPS to share your location.'**
  String get turnOnGpsToShareYourLocation;

  /// No description provided for @turnOnLocationServicesToUseYourCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location Services to use your current position.'**
  String get turnOnLocationServicesToUseYourCurrentPosition;

  /// Application message: twoPartDetails
  ///
  /// In en, this message translates to:
  /// **'{value} • {secondValue}'**
  String twoPartDetails(String value, String secondValue);

  /// Application message: twoPartSummary
  ///
  /// In en, this message translates to:
  /// **'{value} · {secondValue}'**
  String twoPartSummary(String value, String secondValue);

  /// No description provided for @unableToCheckAppRequirements.
  ///
  /// In en, this message translates to:
  /// **'Unable to check app requirements'**
  String get unableToCheckAppRequirements;

  /// No description provided for @unableToLoadThePrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the privacy notice'**
  String get unableToLoadThePrivacyNotice;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @underreview.
  ///
  /// In en, this message translates to:
  /// **'underReview'**
  String get underreview;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get underReview;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownApplicationEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Unknown application environment.'**
  String get unknownApplicationEnvironment;

  /// No description provided for @unknownUntilManuallyReopened.
  ///
  /// In en, this message translates to:
  /// **'Unknown / until manually reopened'**
  String get unknownUntilManuallyReopened;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @unsettledCash.
  ///
  /// In en, this message translates to:
  /// **'Unsettled cash'**
  String get unsettledCash;

  /// No description provided for @unsupportedOfflineCommand.
  ///
  /// In en, this message translates to:
  /// **'Unsupported offline command.'**
  String get unsupportedOfflineCommand;

  /// Application message: updateAppBeforeContinuingToUseBookingAndPaymentServices
  ///
  /// In en, this message translates to:
  /// **'Update {brandName} before continuing to use booking and payment services.'**
  String updateAppBeforeContinuingToUseBookingAndPaymentServices(
    String brandName,
  );

  /// No description provided for @updateApplication.
  ///
  /// In en, this message translates to:
  /// **'Update application'**
  String get updateApplication;

  /// Application message: updatedSAgoValue
  ///
  /// In en, this message translates to:
  /// **'updated {value}s ago'**
  String updatedSAgoValue(String value);

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @updateRequired.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequired;

  /// No description provided for @updateYourDriverDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your driver details'**
  String get updateYourDriverDetails;

  /// No description provided for @updatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Updating route...'**
  String get updatingRoute;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// Application message: uploadValue
  ///
  /// In en, this message translates to:
  /// **'Upload {value}'**
  String uploadValue(String value);

  /// No description provided for @useAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get useAtLeast8Characters;

  /// No description provided for @useAtLeastEightCharactersAvoidAPasswordYouUseOnAnotherService.
  ///
  /// In en, this message translates to:
  /// **'Use at least eight characters. Avoid a password you use on another service.'**
  String get useAtLeastEightCharactersAvoidAPasswordYouUseOnAnotherService;

  /// No description provided for @useLettersSpacesHyphensApostrophesOrPeriodsInYourName.
  ///
  /// In en, this message translates to:
  /// **'Use letters, spaces, hyphens, apostrophes or periods in your name'**
  String get useLettersSpacesHyphensApostrophesOrPeriodsInYourName;

  /// No description provided for @useMyCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// No description provided for @useNow.
  ///
  /// In en, this message translates to:
  /// **'Use now'**
  String get useNow;

  /// No description provided for @useThisOnlyIfYouCannotCompleteThePickupTheTouristWillDecide.
  ///
  /// In en, this message translates to:
  /// **'Use this only if you cannot complete the pickup. The tourist will decide whether to search for another verified driver or cancel free of charge. Explain what happened.'**
  String get useThisOnlyIfYouCannotCompleteThePickupTheTouristWillDecide;

  /// No description provided for @vehicleAndReliability.
  ///
  /// In en, this message translates to:
  /// **'Vehicle and reliability'**
  String get vehicleAndReliability;

  /// No description provided for @vehicleImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Vehicle image selected'**
  String get vehicleImageSelected;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle info'**
  String get vehicleInfo;

  /// No description provided for @vehicleInspection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle inspection'**
  String get vehicleInspection;

  /// No description provided for @vehicleInspectionExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'vehicle_inspection_expires_on'**
  String get vehicleInspectionExpiresOn;

  /// Application message: vehicleInspectionValue
  ///
  /// In en, this message translates to:
  /// **'Vehicle inspection: {value}'**
  String vehicleInspectionValue(String value);

  /// No description provided for @vehicleIsSafeResumeTrip.
  ///
  /// In en, this message translates to:
  /// **'Vehicle is safe · resume trip'**
  String get vehicleIsSafeResumeTrip;

  /// No description provided for @vehicleProblem.
  ///
  /// In en, this message translates to:
  /// **'vehicle problem'**
  String get vehicleProblem;

  /// No description provided for @vehicleProblemPauseTripSafely.
  ///
  /// In en, this message translates to:
  /// **'Vehicle problem · pause trip safely'**
  String get vehicleProblemPauseTripSafely;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Application message: verifiedAppDriver
  ///
  /// In en, this message translates to:
  /// **'Verified {brandName} driver'**
  String verifiedAppDriver(String brandName);

  /// No description provided for @verifiedNearThePickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Verified near the pickup point'**
  String get verifiedNearThePickupPoint;

  /// No description provided for @verifiedPickupArrivalIsRequiredBeforeReportingANoShow.
  ///
  /// In en, this message translates to:
  /// **'Verified pickup arrival is required before reporting a no-show.'**
  String get verifiedPickupArrivalIsRequiredBeforeReportingANoShow;

  /// No description provided for @verifiedTourist.
  ///
  /// In en, this message translates to:
  /// **'Verified tourist'**
  String get verifiedTourist;

  /// No description provided for @verifyLocalAgencyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Verify local agency numbers'**
  String get verifyLocalAgencyNumbers;

  /// No description provided for @verifyPickup.
  ///
  /// In en, this message translates to:
  /// **'Verify pickup'**
  String get verifyPickup;

  /// No description provided for @verifyPickupCodeStart.
  ///
  /// In en, this message translates to:
  /// **'Verify pickup code & start'**
  String get verifyPickupCodeStart;

  /// No description provided for @viewActiveDriversOnTheMap.
  ///
  /// In en, this message translates to:
  /// **'View active drivers on the map'**
  String get viewActiveDriversOnTheMap;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewAndManageTouristAccounts.
  ///
  /// In en, this message translates to:
  /// **'View and manage tourist accounts'**
  String get viewAndManageTouristAccounts;

  /// No description provided for @viewBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'View booking requests'**
  String get viewBookingRequests;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View map'**
  String get viewMap;

  /// No description provided for @viewMyTrips.
  ///
  /// In en, this message translates to:
  /// **'View my trips'**
  String get viewMyTrips;

  /// No description provided for @viewScheduledBooking.
  ///
  /// In en, this message translates to:
  /// **'View scheduled booking'**
  String get viewScheduledBooking;

  /// Application message: viewValue
  ///
  /// In en, this message translates to:
  /// **'View {value}'**
  String viewValue(String value);

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @visibleToTourists.
  ///
  /// In en, this message translates to:
  /// **'Visible to tourists'**
  String get visibleToTourists;

  /// No description provided for @waitForTheMobileMapToLoadBeforeConfirmingAnExactPickupPin.
  ///
  /// In en, this message translates to:
  /// **'Wait for the mobile map to load before confirming an exact pickup pin.'**
  String get waitForTheMobileMapToLoadBeforeConfirmingAnExactPickupPin;

  /// No description provided for @waitForTheTouristToConfirmThisStop.
  ///
  /// In en, this message translates to:
  /// **'Wait for the tourist to confirm this stop.'**
  String get waitForTheTouristToConfirmThisStop;

  /// No description provided for @waitForThisDriver.
  ///
  /// In en, this message translates to:
  /// **'Wait for this driver'**
  String get waitForThisDriver;

  /// No description provided for @waitingForADriverToAcceptYouCanLeaveThisPageAndResume.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a driver to accept. You can leave this page and resume from Trips.'**
  String get waitingForADriverToAcceptYouCanLeaveThisPageAndResume;

  /// No description provided for @waitingForAnApprovedDriverToAcceptYourRequest.
  ///
  /// In en, this message translates to:
  /// **'Waiting for an approved driver to accept your request.'**
  String get waitingForAnApprovedDriverToAcceptYourRequest;

  /// No description provided for @waitingForCashReturnConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for cash return confirmation'**
  String get waitingForCashReturnConfirmation;

  /// No description provided for @waitingForLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for live location'**
  String get waitingForLiveLocation;

  /// No description provided for @waitingForTheOtherCashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other cash confirmation'**
  String get waitingForTheOtherCashConfirmation;

  /// No description provided for @waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other participant. Navigation stays on the current route.'**
  String get waitingForTheOtherParticipantNavigationStaysOnTheCurrentRoute;

  /// No description provided for @waitingForTheTouristSDecision.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the tourist’s decision.'**
  String get waitingForTheTouristSDecision;

  /// No description provided for @waitingForTheTouristToChooseDoNotProceedToPickup.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the tourist to choose. Do not proceed to pickup.'**
  String get waitingForTheTouristToChooseDoNotProceedToPickup;

  /// No description provided for @waitingPeriodCompleted.
  ///
  /// In en, this message translates to:
  /// **'Waiting period completed'**
  String get waitingPeriodCompleted;

  /// No description provided for @waived.
  ///
  /// In en, this message translates to:
  /// **'Waived'**
  String get waived;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @weHaveSentPasswordRecoveryInstructionsToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'We have sent password recovery instructions to your email.'**
  String get weHaveSentPasswordRecoveryInstructionsToYourEmail;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @weLlSendNearbyBookingsYourWay.
  ///
  /// In en, this message translates to:
  /// **'We’ll send nearby bookings your way.'**
  String get weLlSendNearbyBookingsYourWay;

  /// No description provided for @weWillRemindYouAndStartMatching30MinutesBeforePickup.
  ///
  /// In en, this message translates to:
  /// **'We will remind you and start matching 30 minutes before pickup.'**
  String get weWillRemindYouAndStartMatching30MinutesBeforePickup;

  /// No description provided for @whatDidYouLikeOrDislike.
  ///
  /// In en, this message translates to:
  /// **'What did you like or dislike?'**
  String get whatDidYouLikeOrDislike;

  /// No description provided for @whatSIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get whatSIncluded;

  /// No description provided for @whenYouGetNotificationsTheyWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'When you get notifications, they will appear here.'**
  String get whenYouGetNotificationsTheyWillAppearHere;

  /// No description provided for @whereWouldYouLikeToGo.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to go?'**
  String get whereWouldYouLikeToGo;

  /// Application message: willBeCompletedInThePaymongoTestEnvironmentValue
  ///
  /// In en, this message translates to:
  /// **'{value} will be completed in the PayMongo test environment.'**
  String willBeCompletedInThePaymongoTestEnvironmentValue(String value);

  /// No description provided for @youAlreadyHaveAnActiveBookingOpenTripsToContinueOrCancelIt.
  ///
  /// In en, this message translates to:
  /// **'You already have an active booking. Open Trips to continue or cancel it.'**
  String get youAlreadyHaveAnActiveBookingOpenTripsToContinueOrCancelIt;

  /// No description provided for @youAreTogether.
  ///
  /// In en, this message translates to:
  /// **'You are together'**
  String get youAreTogether;

  /// No description provided for @youChoseToWaitTheDriverMustConfirmTheVehicleIsSafeBefore.
  ///
  /// In en, this message translates to:
  /// **'You chose to wait. The driver must confirm the vehicle is safe before navigation resumes.'**
  String get youChoseToWaitTheDriverMustConfirmTheVehicleIsSafeBefore;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @yourAccountCannotPerformThisActionRefreshYourAccountOrContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Your account cannot perform this action. Refresh your account or contact support.'**
  String
  get yourAccountCannotPerformThisActionRefreshYourAccountOrContactSupport;

  /// No description provided for @yourAccountCanUploadApplicationDocumentsAndCheckApprovalGoingOnlineAndAccepting.
  ///
  /// In en, this message translates to:
  /// **'Your account can upload application documents and check approval. Going online and accepting trips require administrator approval.'**
  String
  get yourAccountCanUploadApplicationDocumentsAndCheckApprovalGoingOnlineAndAccepting;

  /// No description provided for @yourAccreditationIsVerified.
  ///
  /// In en, this message translates to:
  /// **'Your accreditation is verified'**
  String get yourAccreditationIsVerified;

  /// No description provided for @yourActivity.
  ///
  /// In en, this message translates to:
  /// **'Your activity'**
  String get yourActivity;

  /// No description provided for @yourAdministratorRoleDoesNotIncludeThisArea.
  ///
  /// In en, this message translates to:
  /// **'Your administrator role does not include this area.'**
  String get yourAdministratorRoleDoesNotIncludeThisArea;

  /// No description provided for @yourAssignedTouristCanSeeYourLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Your assigned tourist can see your live location'**
  String get yourAssignedTouristCanSeeYourLiveLocation;

  /// No description provided for @yourCompletedRidesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your completed rides will appear here.'**
  String get yourCompletedRidesWillAppearHere;

  /// No description provided for @yourDocumentsAreUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your documents are under review.'**
  String get yourDocumentsAreUnderReview;

  /// No description provided for @yourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get yourDriver;

  /// No description provided for @youReOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get youReOffline;

  /// No description provided for @youReReadyToRide.
  ///
  /// In en, this message translates to:
  /// **'You’re ready to ride'**
  String get youReReadyToRide;

  /// Application message: yourFeedbackHelpsKeepAppTrusted
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps keep {brandName} trusted.'**
  String yourFeedbackHelpsKeepAppTrusted(String brandName);

  /// No description provided for @yourFixedFareRouteAndPaymentRecordStayUnchangedThePreviousDriverIs.
  ///
  /// In en, this message translates to:
  /// **'Your fixed fare, route, and payment record stay unchanged. The previous driver is released and a new 10-minute search begins.'**
  String get yourFixedFareRouteAndPaymentRecordStayUnchangedThePreviousDriverIs;

  /// No description provided for @yourGuideYourRideInBustos.
  ///
  /// In en, this message translates to:
  /// **'Your guide, your ride in Bustos'**
  String get yourGuideYourRideInBustos;

  /// No description provided for @yourJourneyYourWay.
  ///
  /// In en, this message translates to:
  /// **'Your journey, your way'**
  String get yourJourneyYourWay;

  /// No description provided for @yourLocalJourneyStartsHere.
  ///
  /// In en, this message translates to:
  /// **'Your local journey starts here'**
  String get yourLocalJourneyStartsHere;

  /// No description provided for @yourPreviousCodeWillStopWorkingShareTheNewCodeOnlyAfterBoarding.
  ///
  /// In en, this message translates to:
  /// **'Your previous code will stop working. Share the new code only after boarding. You can request a new code once every five minutes.'**
  String get yourPreviousCodeWillStopWorkingShareTheNewCodeOnlyAfterBoarding;

  /// No description provided for @yourRidesAndReceipts.
  ///
  /// In en, this message translates to:
  /// **'Your rides and receipts'**
  String get yourRidesAndReceipts;

  /// No description provided for @yourTourIsReservedDriverMatchingBegins30MinutesBeforePickupAndReminders.
  ///
  /// In en, this message translates to:
  /// **'Your tour is reserved. Driver matching begins 30 minutes before pickup, and reminders will appear in Notifications.'**
  String
  get yourTourIsReservedDriverMatchingBegins30MinutesBeforePickupAndReminders;

  /// No description provided for @yourTravel.
  ///
  /// In en, this message translates to:
  /// **'Your travel'**
  String get yourTravel;

  /// Application message: youWillBeSentToPaymongoTestCheckoutPaymentIsConfirmedOnlyAfter
  ///
  /// In en, this message translates to:
  /// **'You will be sent to PayMongo test checkout. Payment is confirmed only after the secure webhook reaches {brandName}.'**
  String youWillBeSentToPaymongoTestCheckoutPaymentIsConfirmedOnlyAfter(
    String brandName,
  );

  /// No description provided for @useDeviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get useDeviceLanguage;

  /// No description provided for @philippineTime.
  ///
  /// In en, this message translates to:
  /// **'Philippine time'**
  String get philippineTime;

  /// No description provided for @philippineDateTime.
  ///
  /// In en, this message translates to:
  /// **'{value} ({timeZone})'**
  String philippineDateTime(String value, String timeZone);

  /// No description provided for @minutesDuration.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min} other{{count} min}}'**
  String minutesDuration(int count);

  /// No description provided for @hoursDuration.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String hoursDuration(int count);

  /// No description provided for @hoursMinutesDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursMinutesDuration(int hours, int minutes);

  /// No description provided for @numberOfTrips.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip} other{{count} trips}}'**
  String numberOfTrips(int count);

  /// No description provided for @activeTripLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'{brandName} trip location active'**
  String activeTripLocationTitle(String brandName);

  /// No description provided for @notificationUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'{brandName} update'**
  String notificationUpdateTitle(String brandName);

  /// No description provided for @fieldMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'{field} must be between {minimum} and {maximum}.'**
  String fieldMustBeBetween(String field, int minimum, int maximum);

  /// No description provided for @selectedDestinationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} destination} other{{count} destinations}}'**
  String selectedDestinationCount(int count);

  /// No description provided for @spotCount.
  ///
  /// In en, this message translates to:
  /// **'{count} spots'**
  String spotCount(int count);

  /// No description provided for @buildYourDayWithStops.
  ///
  /// In en, this message translates to:
  /// **'Build your day ({count} stops)'**
  String buildYourDayWithStops(int count);

  /// No description provided for @cancellationWithReason.
  ///
  /// In en, this message translates to:
  /// **'{result}. Reason: {reason}'**
  String cancellationWithReason(String result, String reason);

  /// No description provided for @cashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{payment} confirmed by {actor}; {confirmation}.'**
  String cashConfirmation(String payment, String actor, String confirmation);

  /// No description provided for @bothPartiesConfirmed.
  ///
  /// In en, this message translates to:
  /// **'both parties confirmed'**
  String get bothPartiesConfirmed;

  /// No description provided for @awaitingOtherParty.
  ///
  /// In en, this message translates to:
  /// **'awaiting the other party'**
  String get awaitingOtherParty;

  /// No description provided for @exportPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get exportPending;

  /// No description provided for @exportFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get exportFulfilled;

  /// No description provided for @exportRejected.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get exportRejected;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @signInDidNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not complete.'**
  String get signInDidNotComplete;

  /// No description provided for @authResetConfigurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Password recovery is not configured for this build.'**
  String get authResetConfigurationRequired;

  /// No description provided for @pickupRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Pickup-code recovery could not be confirmed. Retry from your booking.'**
  String get pickupRecoveryFailed;

  /// No description provided for @offlineReplayUnsafe.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be retried offline.'**
  String get offlineReplayUnsafe;

  /// No description provided for @selectedStopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected stops'**
  String selectedStopsCount(int count);

  /// No description provided for @cancellationGraceExpired.
  ///
  /// In en, this message translates to:
  /// **'The {minutes}-minute grace period has ended. The published {percent}% cancellation fee is {fee}. Give the reason before confirming.'**
  String cancellationGraceExpired(int minutes, int percent, String fee);

  /// No description provided for @arrivedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'I have arrived at pickup'**
  String get arrivedAtPickup;

  /// No description provided for @requestPickupReplacement.
  ///
  /// In en, this message translates to:
  /// **'I cannot make this pickup · request replacement'**
  String get requestPickupReplacement;

  /// No description provided for @confirmReachedStop.
  ///
  /// In en, this message translates to:
  /// **'Yes, we reached this stop'**
  String get confirmReachedStop;

  /// No description provided for @reviewFinalCharge.
  ///
  /// In en, this message translates to:
  /// **'Review and decide final charge'**
  String get reviewFinalCharge;

  /// No description provided for @trackingMovementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{distance} {target} · updated {seconds}s ago'**
  String trackingMovementSubtitle(String distance, String target, int seconds);

  /// No description provided for @complianceServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Service area: {name} ({radius} km)'**
  String complianceServiceArea(String name, String radius);

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get sendMessage;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download report'**
  String get downloadReport;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark resolved'**
  String get markResolved;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @savePlace.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get savePlace;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @luggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get luggage;

  /// No description provided for @assistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance'**
  String get assistance;

  /// No description provided for @friendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get friendly;

  /// No description provided for @punctual.
  ///
  /// In en, this message translates to:
  /// **'Punctual'**
  String get punctual;

  /// No description provided for @terrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get terrible;

  /// No description provided for @bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get bad;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get excellent;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @municipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality'**
  String get municipality;

  /// No description provided for @resorts.
  ///
  /// In en, this message translates to:
  /// **'Resorts'**
  String get resorts;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @farmsNature.
  ///
  /// In en, this message translates to:
  /// **'Farms and nature'**
  String get farmsNature;

  /// No description provided for @foodCafes.
  ///
  /// In en, this message translates to:
  /// **'Food and cafés'**
  String get foodCafes;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @tricycle.
  ///
  /// In en, this message translates to:
  /// **'Tricycle'**
  String get tricycle;

  /// No description provided for @oneYearMembership.
  ///
  /// In en, this message translates to:
  /// **'1 yr'**
  String get oneYearMembership;

  /// No description provided for @lastThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get lastThirtyDays;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get lastSevenDays;

  /// No description provided for @newTouristRating.
  ///
  /// In en, this message translates to:
  /// **' 5.0 (New)'**
  String get newTouristRating;

  /// No description provided for @exampleOperatingHours.
  ///
  /// In en, this message translates to:
  /// **'8:00 AM - 5:00 PM'**
  String get exampleOperatingHours;

  /// No description provided for @onePassenger.
  ///
  /// In en, this message translates to:
  /// **'1 passenger'**
  String get onePassenger;

  /// No description provided for @twoPassengers.
  ///
  /// In en, this message translates to:
  /// **'2 passengers'**
  String get twoPassengers;

  /// No description provided for @threePassengers.
  ///
  /// In en, this message translates to:
  /// **'3 passengers'**
  String get threePassengers;

  /// No description provided for @removeSavedPlace.
  ///
  /// In en, this message translates to:
  /// **'Remove saved place'**
  String get removeSavedPlace;

  /// No description provided for @togglePhotoControls.
  ///
  /// In en, this message translates to:
  /// **'Show or hide photo controls'**
  String get togglePhotoControls;

  /// No description provided for @paymentCheckoutCreated.
  ///
  /// In en, this message translates to:
  /// **'Checkout created'**
  String get paymentCheckoutCreated;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payment processing'**
  String get paymentProcessing;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment confirmation'**
  String get paymentAwaitingConfirmation;

  /// No description provided for @paymentRefundDue.
  ///
  /// In en, this message translates to:
  /// **'Refund due'**
  String get paymentRefundDue;

  /// No description provided for @paymentRefundProcessing.
  ///
  /// In en, this message translates to:
  /// **'Refund processing'**
  String get paymentRefundProcessing;

  /// No description provided for @actorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get actorSystem;

  /// No description provided for @statusBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get statusBusy;

  /// No description provided for @privacyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get privacyNoticeTitle;

  /// No description provided for @privacyWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy comes first'**
  String get privacyWelcomeTitle;

  /// No description provided for @privacyWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Before you continue, review how {brandName} uses your information and choose your preferences.'**
  String privacyWelcomeBody(String brandName);

  /// No description provided for @privacyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account and trip details'**
  String get privacyAccountTitle;

  /// No description provided for @privacyAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your details help manage your account, match your ride and keep trip records.'**
  String get privacyAccountBody;

  /// No description provided for @privacyLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location when needed'**
  String get privacyLocationTitle;

  /// No description provided for @privacyLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Location supports pickup and navigation. Background location is requested only for driver service.'**
  String get privacyLocationBody;

  /// No description provided for @privacyChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'You stay in control'**
  String get privacyChoiceTitle;

  /// No description provided for @privacyChoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Crash diagnostics are optional. You can request your data or delete your account in your profile.'**
  String get privacyChoiceBody;

  /// No description provided for @privacyFullNotice.
  ///
  /// In en, this message translates to:
  /// **'Read the full notice'**
  String get privacyFullNotice;

  /// No description provided for @privacyDiagnosticsHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Turning this off does not affect sign-in or bookings.'**
  String get privacyDiagnosticsHelp;

  /// No description provided for @privacyRequiredHelp.
  ///
  /// In en, this message translates to:
  /// **'Accept the notice to continue. Diagnostics are your choice.'**
  String get privacyRequiredHelp;

  /// No description provided for @privacyLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Checking your privacy preferences'**
  String get privacyLoadingLabel;

  /// No description provided for @privacyVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notice version {version}'**
  String privacyVersionLabel(String version);

  /// No description provided for @tickTheAgreementToBook.
  ///
  /// In en, this message translates to:
  /// **'Tick the agreement above the button to book.'**
  String get tickTheAgreementToBook;

  /// No description provided for @driverDocumentsBlockOnline.
  ///
  /// In en, this message translates to:
  /// **'Your driver documents are missing, expired or not yet verified. Check your profile or contact the admin.'**
  String get driverDocumentsBlockOnline;

  /// No description provided for @moveWithin150mOfPickup.
  ///
  /// In en, this message translates to:
  /// **'Move within 150 metres of the pickup point and try again.'**
  String get moveWithin150mOfPickup;

  /// No description provided for @gpsAccuracyTooLow.
  ///
  /// In en, this message translates to:
  /// **'Your GPS signal is too weak. Move to an open area and try again.'**
  String get gpsAccuracyTooLow;

  /// No description provided for @kmFromTown.
  ///
  /// In en, this message translates to:
  /// **'{km} km from town'**
  String kmFromTown(String km);

  /// No description provided for @driverInServiceArea.
  ///
  /// In en, this message translates to:
  /// **'In the Bustos service area'**
  String get driverInServiceArea;

  /// No description provided for @driverOutsideServiceArea.
  ///
  /// In en, this message translates to:
  /// **'{km} km from Bustos'**
  String driverOutsideServiceArea(String km);

  /// No description provided for @noDriversOnlineRightNow.
  ///
  /// In en, this message translates to:
  /// **'No drivers are online right now'**
  String get noDriversOnlineRightNow;

  /// No description provided for @noDriversOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'You can still send the request, but it may expire before anyone accepts. Scheduling for later gives drivers time to see it.'**
  String get noDriversOnlineBody;

  /// No description provided for @scheduleForLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule for later'**
  String get scheduleForLater;

  /// No description provided for @groupOfFourOrMore.
  ///
  /// In en, this message translates to:
  /// **'Group of 4 or more?'**
  String get groupOfFourOrMore;

  /// No description provided for @groupOfFourOrMoreBody.
  ///
  /// In en, this message translates to:
  /// **'A tricycle seats up to 3. Book this one for 3, then ask someone else in your group to book a second tricycle from their own phone for the same tour.'**
  String get groupOfFourOrMoreBody;

  /// No description provided for @locationExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Show where you are on the map'**
  String get locationExplainerTitle;

  /// No description provided for @locationReasonMap.
  ///
  /// In en, this message translates to:
  /// **'See how far each spot is from you.'**
  String get locationReasonMap;

  /// No description provided for @locationReasonPickup.
  ///
  /// In en, this message translates to:
  /// **'Use your current spot as the pickup point, so your driver finds you.'**
  String get locationReasonPickup;

  /// No description provided for @locationReasonPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only used while the app is open. Drivers see your pickup point, not your live location.'**
  String get locationReasonPrivacy;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @inYourTrip.
  ///
  /// In en, this message translates to:
  /// **'In your trip'**
  String get inYourTrip;

  /// No description provided for @openBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Open booking details'**
  String get openBookingDetails;

  /// No description provided for @adminEscalatedOn.
  ///
  /// In en, this message translates to:
  /// **'Escalated to admin'**
  String get adminEscalatedOn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
