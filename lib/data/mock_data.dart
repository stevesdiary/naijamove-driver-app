import 'package:flutter/material.dart';

import 'models.dart';

/// The spec's "Sample Data" table — every screen draws from here so names,
/// plates and amounts match the Rider App.
abstract final class MockData {
  static final now = DateTime(2026, 9, 11, 16, 0);

  static const vehicle = Vehicle(
    make: 'Toyota',
    model: 'Corolla',
    year: 2019,
    colour: 'White',
    plate: 'LND 482 KJ',
    category: VehicleCategory.economy,
  );

  static const driver = DriverProfile(
    firstName: 'Emeka',
    lastName: 'Okafor',
    preferredName: 'Emeka',
    phone: '+234 802 555 0193',
    email: 'emeka.okafor@gmail.com',
    rating: 4.87,
    ratings: 1240,
    trips: 1240,
    memberSince: 2022,
    bio: 'Safe, punctual and I know every shortcut in Lagos. AC always on.',
    tier: DriverTier.gold,
    languages: ['English', 'Igbo', 'Pidgin'],
    acceptanceRate: 94,
    completionRate: 98,
    cancellationRate: 2,
    onTimeRate: 91,
  );

  static const rider = Rider(
    firstName: 'Tunde',
    rating: 4.9,
    trips: 42,
    payment: PaymentMethodType.card,
  );

  static const pickup = Place(
    name: '24 Adetokunbo Ademola St',
    address: '24 Adetokunbo Ademola St, Victoria Island',
    area: 'Victoria Island',
    at: Offset(0.32, 0.62),
  );
  static const destination = Place(
    name: 'Ikeja City Mall',
    address: 'Ikeja City Mall, Alausa, Ikeja',
    area: 'Ikeja',
    at: Offset(0.72, 0.22),
  );
  static const stopLekki = Place(
    name: 'Shoprite, Lekki Phase 1',
    address: 'Shoprite, Admiralty Way, Lekki Phase 1',
    area: 'Lekki',
    at: Offset(0.55, 0.48),
  );

  static const request = TripRequest(
    id: 'NM-TRIP-48213',
    pickup: pickup,
    destination: destination,
    distanceToPickupKm: 1.2,
    distanceKm: 8.4,
    durationMin: 22,
    fare: 1850,
    surge: 1.4,
    category: VehicleCategory.economy,
    rider: rider,
  );

  static const bank = BankAccount(
    bankName: 'GTBank',
    accountNumber: '0123454821',
    holder: 'EMEKA CHUKWUDI OKAFOR',
  );

  static const banks = [
    'GTBank',
    'Access Bank',
    'Zenith Bank',
    'First Bank',
    'UBA',
    'Kuda',
    'OPay',
    'PalmPay',
    'Moniepoint',
  ];

  static const walletBalance = 12600;
  static const todayEarnings = 6200;
  static const todayTrips = 7;
  static const weekEarnings = 28400;
  static const weekTrips = 34;
  static const weekGross = 34600;
  static const weekCommission = 6920;
  static const weekBonuses = 2000;

  static const emergencyContact = EmergencyContact(
    name: 'Ngozi Okafor',
    phone: '+234 803 771 2244',
    relationship: 'Spouse',
  );

  static final trips = <Trip>[
    Trip(
      id: 'T-4821',
      pickup: pickup,
      destination: destination,
      date: DateTime(2026, 9, 11, 15, 36),
      status: TripStatus.completed,
      distanceKm: 8.4,
      durationMin: 22,
      gross: 1850,
      commission: 370,
      bonus: 400,
      tip: 200,
      category: VehicleCategory.economy,
      rider: rider,
      surge: 1.4,
      ratingGiven: 5,
    ),
    Trip(
      id: 'T-4820',
      pickup: const Place(
        name: 'Lekki Phase 1',
        address: 'Admiralty Way, Lekki Phase 1',
        area: 'Lekki',
      ),
      destination: const Place(
        name: 'Yaba',
        address: 'Herbert Macaulay Way, Yaba',
        area: 'Yaba',
      ),
      date: DateTime(2026, 9, 11, 13, 10),
      status: TripStatus.completed,
      distanceKm: 14.1,
      durationMin: 35,
      gross: 2690,
      commission: 540,
      category: VehicleCategory.economy,
      rider: const Rider(
        firstName: 'Amaka',
        rating: 4.8,
        trips: 118,
        payment: PaymentMethodType.cash,
      ),
      ratingGiven: 5,
    ),
    Trip(
      id: 'T-4812',
      pickup: const Place(
        name: 'Bode Thomas St',
        address: 'Bode Thomas St, Surulere',
        area: 'Surulere',
        at: Offset(0.4, 0.5),
      ),
      destination: const Place(
        name: 'Marina',
        address: 'Marina, Lagos Island',
        area: 'Marina',
      ),
      date: DateTime(2026, 9, 10, 20, 5),
      status: TripStatus.noShow,
      distanceKm: 0,
      durationMin: 0,
      gross: 0,
      commission: 0,
      category: VehicleCategory.economy,
      rider: const Rider(
        firstName: 'Seun',
        rating: 4.6,
        trips: 9,
        payment: PaymentMethodType.card,
      ),
      cancellationFee: 200,
      cancelledBy: 'Rider',
      cancelReason: 'Rider no-show',
      waitedSeconds: 340,
    ),
    Trip(
      id: 'T-4801',
      pickup: const Place(
        name: 'Ikeja GRA',
        address: 'Isaac John St, Ikeja GRA',
        area: 'Ikeja',
      ),
      destination: const Place(
        name: 'Murtala Muhammed Airport',
        address: 'MMA2, Ikeja',
        area: 'Airport',
      ),
      date: DateTime(2026, 9, 10, 6, 20),
      status: TripStatus.disputed,
      distanceKm: 6.2,
      durationMin: 18,
      gross: 3900,
      commission: 780,
      category: VehicleCategory.comfort,
      rider: const Rider(
        firstName: 'Bayo',
        rating: 4.7,
        trips: 63,
        payment: PaymentMethodType.transfer,
      ),
    ),
  ];

  static final scheduled = <ScheduledTrip>[
    ScheduledTrip(
      time: DateTime(2026, 9, 11, 16, 30),
      pickup: pickup,
      destination: destination,
      fare: 1850,
      category: VehicleCategory.economy,
    ),
    ScheduledTrip(
      time: DateTime(2026, 9, 12, 7, 0),
      pickup: const Place(
        name: 'Lekki Phase 1',
        address: 'Lekki Phase 1',
        area: 'Lekki Phase 1',
      ),
      destination: const Place(
        name: 'Murtala Muhammed Airport',
        address: 'MMA2, Ikeja',
        area: 'Airport',
      ),
      fare: 4200,
      category: VehicleCategory.comfort,
    ),
    ScheduledTrip(
      time: DateTime(2026, 9, 13, 9, 15),
      pickup: const Place(name: 'Yaba', address: 'Yaba', area: 'Yaba'),
      destination: const Place(
        name: 'Marina',
        address: 'Marina, Lagos Island',
        area: 'Marina',
      ),
      fare: 1600,
      category: VehicleCategory.economy,
    ),
  ];

  static final bonuses = <Bonus>[
    Bonus(
      name: 'Peak Hours Bonus',
      description: 'Complete 5 trips between 5–10 PM',
      progress: 3,
      target: 5,
      reward: 2000,
      status: BonusStatus.active,
      expires: DateTime(2026, 9, 11, 22, 0),
    ),
    Bonus(
      name: 'Weekend Warrior',
      description: 'Earn ₦ 25,000 Sat–Sun',
      progress: 18400,
      target: 25000,
      reward: 5000,
      status: BonusStatus.active,
      progressIsAmount: true,
      expires: DateTime(2026, 9, 13, 23, 59),
    ),
    const Bonus(
      name: 'Airport Runs Bonus',
      description: '3 airport trips in a day',
      progress: 0,
      target: 3,
      reward: 3000,
      status: BonusStatus.upcoming,
      startsLabel: 'Starts tomorrow',
    ),
    Bonus(
      name: 'Rainy Day Bonus',
      description: 'Stayed online through the storm',
      progress: 1,
      target: 1,
      reward: 1500,
      status: BonusStatus.completed,
      paidOn: DateTime(2026, 9, 3),
    ),
    Bonus(
      name: 'First Week Streak',
      description: '7 days online',
      progress: 7,
      target: 7,
      reward: 2500,
      status: BonusStatus.completed,
      paidOn: DateTime(2026, 8, 24),
    ),
  ];

  static final payouts = <Payout>[
    Payout(
      date: DateTime(2026, 9, 10, 18, 2),
      amount: 5000,
      status: PayoutStatus.completed,
      bank: 'GTBank',
    ),
    Payout(
      date: DateTime(2026, 9, 8, 9, 0),
      amount: 10000,
      status: PayoutStatus.completed,
      bank: 'GTBank',
    ),
    Payout(
      date: DateTime(2026, 9, 5, 21, 40),
      amount: 8000,
      status: PayoutStatus.processing,
      bank: 'GTBank',
    ),
  ];

  static final transactions = <WalletTx>[
    WalletTx(
      kind: TxKind.trip,
      title: 'Trip · VI → Ikeja',
      subtitle: 'Card',
      date: DateTime(2026, 9, 11, 15, 58),
      amount: 1480,
      tripId: 'T-4821',
    ),
    WalletTx(
      kind: TxKind.bonus,
      title: 'Peak Hours Bonus',
      subtitle: 'Bonus paid',
      date: DateTime(2026, 9, 11, 22, 2),
      amount: 2000,
    ),
    WalletTx(
      kind: TxKind.payout,
      title: 'Payout to GTBank ••• 4821',
      subtitle: 'Instant withdrawal',
      date: DateTime(2026, 9, 10, 18, 2),
      amount: -5000,
      payoutStatus: PayoutStatus.completed,
    ),
    WalletTx(
      kind: TxKind.adjustment,
      title: 'Fare correction · NMD-2026-00391',
      subtitle: 'Support adjustment',
      date: DateTime(2026, 9, 10, 14, 14),
      amount: 300,
    ),
    WalletTx(
      kind: TxKind.trip,
      title: 'Trip · Lekki → Yaba',
      subtitle: 'Cash collected',
      date: DateTime(2026, 9, 11, 13, 45),
      amount: 2150,
      tripId: 'T-4820',
    ),
  ];

  static final documents = <DriverDocument>[
    DriverDocument(
      name: "Driver's Licence",
      status: DocStatus.verified,
      expiry: DateTime(2028, 6, 2),
      icon: Icons.badge_rounded,
    ),
    DriverDocument(
      name: 'Vehicle Licence',
      status: DocStatus.verified,
      expiry: DateTime(2026, 11, 30),
      icon: Icons.directions_car_rounded,
    ),
    DriverDocument(
      name: 'Proof of Insurance',
      status: DocStatus.expiringSoon,
      expiry: DateTime(2026, 9, 25),
      icon: Icons.shield_rounded,
    ),
    const DriverDocument(
      name: 'Vehicle Inspection Certificate',
      status: DocStatus.rejected,
      rejectionReason: 'Image is blurry — please retake in good light',
      icon: Icons.fact_check_rounded,
    ),
    const DriverDocument(
      name: 'Profile Photo',
      status: DocStatus.verified,
      icon: Icons.account_circle_rounded,
    ),
  ];

  static final notifications = <AppNotification>[
    AppNotification(
      title: 'Trip completed',
      body: '₦ 1,480 added to your wallet',
      time: DateTime(2026, 9, 11, 15, 58),
      kind: NotificationKind.trip,
      unread: true,
    ),
    AppNotification(
      title: 'Payout sent',
      body: '₦ 5,000 sent to GTBank ••• 4821',
      time: DateTime(2026, 9, 10, 18, 2),
      kind: NotificationKind.earnings,
      unread: true,
    ),
    AppNotification(
      title: 'Bonus unlocked!',
      body: 'You completed the Peak Hours Bonus — ₦ 2,000',
      time: DateTime(2026, 9, 10, 22, 2),
      kind: NotificationKind.bonus,
    ),
    AppNotification(
      title: 'Document expiring',
      body: 'Your insurance expires in 14 days',
      time: DateTime(2026, 9, 10, 9, 0),
      kind: NotificationKind.safety,
    ),
    AppNotification(
      title: 'Licence verified',
      body: "Your driver's licence has been verified",
      time: DateTime(2026, 9, 9, 14, 14),
      kind: NotificationKind.account,
    ),
  ];

  static const starDistribution = [81, 12, 4, 2, 1];
  static const compliments = [
    ('Safe driving', 412),
    ('On time', 389),
    ('Friendly', 301),
    ('Clean car', 278),
  ];

  static final feedback = <Feedback>[
    Feedback(
      stars: 5,
      tags: ['Friendly', 'Clean car'],
      comment: 'Smooth ride, AC was perfect',
      date: DateTime(2026, 9, 11),
    ),
    Feedback(stars: 4, tags: ['On time'], date: DateTime(2026, 9, 10)),
    Feedback(
      stars: 5,
      tags: ['Safe driving'],
      comment: 'Knew a shortcut past the Lekki toll traffic.',
      date: DateTime(2026, 9, 9),
    ),
  ];

  static const caseRef = 'NMD-2026-00391';

  static final cases = <SupportCase>[
    SupportCase(
      ref: caseRef,
      title: 'Payment or earnings issue',
      icon: Icons.credit_card_rounded,
      status: CaseStatus.open,
      preview: "Support: Thanks Emeka, we're checking the commission on…",
      updated: DateTime(2026, 9, 11, 14, 10),
      unread: true,
      tripLabel: 'Trip VI → Ikeja · Submitted today 4:10 PM · 1 attachment',
      messages: [
        ChatMessage(
          text: 'Case opened',
          time: DateTime(2026, 9, 11, 16, 10),
          sender: MessageSender.system,
        ),
        ChatMessage(
          text:
              'The fare showed ₦ 1,850 but my net came to ₦ 1,480. Was commission applied twice?',
          time: DateTime(2026, 9, 11, 16, 10),
          sender: MessageSender.driver,
        ),
        ChatMessage(
          text: 'Agent assigned',
          time: DateTime(2026, 9, 11, 16, 15),
          sender: MessageSender.system,
        ),
        ChatMessage(
          text:
              "Hi Emeka, thanks for flagging this. Commission was ₦ 370 (20%). I'm checking whether the surge bonus was credited.",
          time: DateTime(2026, 9, 11, 16, 18),
          sender: MessageSender.agent,
        ),
      ],
    ),
    SupportCase(
      ref: 'NMD-2026-00377',
      title: 'Document rejected',
      icon: Icons.description_rounded,
      status: CaseStatus.pendingAgent,
      preview: "You: I've re-uploaded the inspection certificate",
      updated: DateTime(2026, 9, 10, 11, 0),
    ),
    SupportCase(
      ref: 'NMD-2026-00340',
      title: 'Problem with a trip',
      icon: Icons.directions_car_rounded,
      status: CaseStatus.resolved,
      preview: 'Cancellation fee of ₦ 200 credited',
      updated: DateTime(2026, 8, 28),
      resolution: 'Cancellation fee of ₦ 200 credited to your wallet',
    ),
  ];

  static final riderChat = <ChatMessage>[
    ChatMessage(
      text: "I'm at the gate, black jacket",
      time: DateTime(2026, 9, 11, 15, 40),
      sender: MessageSender.rider,
    ),
    ChatMessage(
      text: "I'm on my way",
      time: DateTime(2026, 9, 11, 15, 40),
      sender: MessageSender.driver,
    ),
  ];

  static const riderQuickReplies = [
    "I'm on my way",
    "I've arrived",
    "I'm outside",
    'Traffic — 5 more min',
    'Where exactly are you?',
    'Call me',
  ];

  static const supportQuickReplies = [
    "Yes, that's correct",
    'No, still an issue',
    'Thank you',
  ];

  static const issueCategories = [
    (Icons.credit_card_rounded, 'I have a payment or earnings issue'),
    (Icons.directions_car_rounded, 'There was a problem with a trip'),
    (Icons.description_rounded, 'My document was rejected or expired'),
    (Icons.shield_rounded, 'I had a safety concern'),
    (Icons.emoji_events_rounded, 'I have a question about my rating'),
    (Icons.card_giftcard_rounded, 'I have a question about a bonus'),
    (Icons.lock_rounded, 'Account or login issue'),
    (Icons.chat_bubble_rounded, 'Other — describe your issue'),
  ];

  static const faqQuestions = [
    'When do I get paid?',
    'How is commission calculated?',
    'What if a rider cancels?',
    'How does surge pricing work?',
    'What documents do I need?',
    'How is my Top Driver tier calculated?',
  ];

  static const faq = FaqArticle(
    title: 'When do I get paid?',
    breadcrumb: 'Help › Earnings › Payouts',
    intro:
        'Your earnings land in your NaijaMove Wallet the moment a trip completes. You can withdraw any time, or let the weekly auto-payout do it for you.',
    steps: [
      'Open the Earnings tab',
      'Tap Withdraw',
      'Choose an amount and confirm',
    ],
    highlight:
        'Instant withdrawals arrive within 10 minutes; a weekly auto-payout runs every Monday at 6 AM.',
    tip: 'Withdraw before 10 PM to avoid bank downtime.',
    related: [
      'How is commission calculated?',
      'Why was my payout delayed?',
      'Understanding bonuses',
    ],
  );

  static const cancelReasons = [
    "Rider isn't responding",
    'Rider asked me to cancel',
    'Pickup location is wrong or unreachable',
    'Too many passengers or items',
    'Vehicle issue',
    'Personal emergency',
    'Other',
  ];

  static const riderFeedbackTags = [
    'Polite',
    'Ready on time',
    'Respectful',
    'Difficult pickup',
  ];
}
