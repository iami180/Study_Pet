import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/models.dart';
import 'state/app_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FocusPetBootstrap());
}

class Palette {
  static const ink = Color(0xFF17233A);
  static const muted = Color(0xFF667085);
  static const primary = Color(0xFF4E68D8);
  static const mint = Color(0xFF47C3A4);
  static const coral = Color(0xFFFF8068);
  static const amber = Color(0xFFFFC24C);
  static const lightBackground = Color(0xFFF5F7F4);
  static const darkBackground = Color(0xFF101A24);
}

class FocusPetBootstrap extends StatefulWidget {
  const FocusPetBootstrap({super.key});

  @override
  State<FocusPetBootstrap> createState() => _FocusPetBootstrapState();
}

class _FocusPetBootstrapState extends State<FocusPetBootstrap> {
  final controller = AppController();

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FocusPet',
        themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: !controller.ready
            ? const SplashScreen()
            : controller.onboarded
                ? AppShell(controller: controller)
                : OnboardingScreen(controller: controller),
      ),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? Palette.darkBackground : Palette.lightBackground;
  final surface = dark ? const Color(0xFF182632) : Colors.white;
  final text = dark ? const Color(0xFFF1F5F4) : Palette.ink;
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    brightness: brightness,
    primary: dark ? const Color(0xFF95AAFF) : Palette.primary,
    secondary: Palette.mint,
    surface: surface,
    error: Palette.coral,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: text,
          displayColor: text,
        ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: scheme.primary.withValues(alpha: .14),
      labelTextStyle: WidgetStateProperty.all(
        TextStyle(fontWeight: FontWeight.w700, color: text, fontSize: 12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: surface,
      selectedColor: scheme.primary.withValues(alpha: .16),
      labelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? scheme.primary : text,
        ),
      ),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PetIllustration(
                kind: PetKind.robot, state: PetState.focused, size: 116),
            const SizedBox(height: 20),
            Text('FocusPet',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pages = const [
    (
      'Build focus habits',
      'Start a session, finish the timer, and build your daily streak.',
      Icons.timer_outlined
    ),
    (
      'Grow your study buddy',
      'Every completed session gives XP and coins for Lumi.',
      Icons.auto_awesome_outlined
    ),
    (
      'Track real progress',
      'See your focus time by day and by subject.',
      Icons.bar_chart_rounded
    ),
  ];
  final pageController = PageController();
  final nameController = TextEditingController();
  int page = 0;
  PetKind selectedPet = PetKind.robot;

  @override
  void dispose() {
    pageController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectingPet = page == pages.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('FocusPet',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: selectingPet
                    ? _PetSelection(
                        selected: selectedPet,
                        nameController: nameController,
                        onSelected: (pet) => setState(() => selectedPet = pet),
                      )
                    : PageView.builder(
                        controller: pageController,
                        itemCount: pages.length,
                        onPageChanged: (value) => setState(() => page = value),
                        itemBuilder: (context, index) => _IntroPage(
                          title: pages[index].$1,
                          copy: pages[index].$2,
                          icon: pages[index].$3,
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length + 1,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 7,
                    width: index == page ? 26 : 7,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FilledButton(
                onPressed: () async {
                  if (selectingPet) {
                    final entered = nameController.text.trim();
                    if (entered.isNotEmpty) {
                      await widget.controller.updateUserName(entered);
                    }
                    await widget.controller.finishOnboarding(selectedPet);
                  } else if (page == pages.length - 1) {
                    setState(() => page = pages.length);
                  } else {
                    await pageController.nextPage(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut);
                  }
                },
                child: Text(selectingPet ? 'Start focusing' : 'Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage(
      {required this.title, required this.copy, required this.icon});

  final String title;
  final String copy;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 148,
          height: 148,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(icon,
              size: 68, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 42),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Text(copy,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Palette.muted, height: 1.45)),
      ],
    );
  }
}

class _PetSelection extends StatelessWidget {
  const _PetSelection({
    required this.selected,
    required this.onSelected,
    required this.nameController,
  });

  final PetKind selected;
  final ValueChanged<PetKind> onSelected;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text('What should we call you?',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: 'Your name (optional)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          Text('Choose your study buddy',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('You can change their accessories later.',
              style: TextStyle(color: Palette.muted)),
          const SizedBox(height: 28),
        Row(
          children: PetKind.values.map((pet) {
            final active = pet == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelected(pet),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .1)
                          : Theme.of(context).cardColor,
                      border: Border.all(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: active ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        PetIllustration(
                            kind: pet, state: PetState.happy, size: 66),
                        const SizedBox(height: 10),
                        Text(pet.label,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        ],
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  void openFocus() => setState(() => index = 2);

  Future<void> openActiveSession() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => ActiveFocusScreen(controller: widget.controller)),
    );
    if (result == true && mounted) {
      setState(() => index = 0);
    }
  }

  Future<void> startPlanItem(DailyPlanItem item) async {
    final started = await widget.controller.startSession(
      minutes: item.recommendedMinutes,
      subjectId: item.subjectId,
      taskId: item.taskId,
      mode: FocusMode.normal,
    );
    if (!started) {
      await openActiveSession();
      return;
    }
    await openActiveSession();
  }

  Future<void> startTask(StudyTask task) async {
    final started = await widget.controller.startSession(
      minutes: task.estimatedMinutes,
      subjectId: task.subjectId,
      taskId: task.id,
      mode: FocusMode.normal,
    );
    if (!started) {
      await openActiveSession();
      return;
    }
    await openActiveSession();
  }

  Future<void> quickStart(int minutes) async {
    final plan = widget.controller.dailyPlan;
    // Link the top planned item so finishing a quick session actually advances
    // today's plan instead of starting a disconnected timer.
    final subjectId = plan.isNotEmpty
        ? plan.first.subjectId
        : widget.controller.subjects.first.id;
    final started = await widget.controller.startSession(
      minutes: minutes,
      subjectId: subjectId,
      taskId: plan.isNotEmpty ? plan.first.taskId : null,
      mode: FocusMode.normal,
    );
    if (!started) {
      await openActiveSession();
      return;
    }
    await openActiveSession();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
          controller: widget.controller,
          onStartFocus: openFocus,
          onQuickStart: quickStart,
          onResume: openActiveSession,
          onStartPlanItem: startPlanItem),
      PlanScreen(controller: widget.controller, onStartTask: startTask),
      FocusSetupScreen(
          controller: widget.controller, onStarted: openActiveSession),
      PetScreen(controller: widget.controller),
      StatsScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Plan'),
          NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer_rounded),
              label: 'Focus'),
          NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets),
              label: 'Pet'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Stats'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {required this.controller,
      required this.onStartFocus,
      required this.onQuickStart,
      required this.onResume,
      required this.onStartPlanItem,
      super.key});

  final AppController controller;
  final VoidCallback onStartFocus;
  final ValueChanged<int> onQuickStart;
  final VoidCallback onResume;
  final ValueChanged<DailyPlanItem> onStartPlanItem;

  @override
  Widget build(BuildContext context) {
    final quests = controller.dailyQuests;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_greeting()}, ${controller.userName}!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Ready to focus?',
                      style: TextStyle(color: Palette.muted, fontSize: 16)),
                ],
              ),
            ),
            _Pill(
                icon: Icons.local_fire_department_rounded,
                value: '${controller.currentStreak}',
                color: Palette.coral),
            if (controller.hasFreezeAvailable && controller.currentStreak > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: 'Streak freeze available this week',
                  child: Icon(Icons.ac_unit_rounded,
                      color: Colors.lightBlue.shade300, size: 18),
                ),
              ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsScreen(controller: controller))),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SummaryPanel(controller: controller),
        const SizedBox(height: 14),
        _PetPanel(controller: controller),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: _SectionHeader(title: 'Today\'s plan')),
          TextButton.icon(
            onPressed: () => _showTodayPlanEditor(context, controller),
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Add'),
          ),
        ]),
        const SizedBox(height: 10),
        _DailyPlanCard(
            controller: controller, onStartPlanItem: onStartPlanItem),
        if (!controller.hasActiveSession &&
            controller.inProgressTasks.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ContinueTasksCard(controller: controller),
        ],
        if (controller.upcomingExams.isNotEmpty) ...[
          const SizedBox(height: 18),
          _UpcomingExamsCard(
              controller: controller, exams: controller.upcomingExams),
        ],
        if (controller.unresolvedMistakeCount > 0) ...[
          const SizedBox(height: 18),
          _MistakeReviewPrompt(controller: controller),
        ],
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Quick start'),
        const SizedBox(height: 10),
        if (controller.hasActiveSession)
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(controller.pendingReward == null
                ? 'Return to active session'
                : 'Claim session reward'),
          )
        else
          Row(children: [
            for (final minutes in [15, 25, 45])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => onQuickStart(minutes),
                    child: Text('$minutes min'),
                  ),
                ),
              ),
          ]),
        if (!controller.hasActiveSession) ...[
          const SizedBox(height: 4),
          TextButton(
              onPressed: onStartFocus,
              child: const Text('Set up a focus session')),
        ],
        const SizedBox(height: 22),
        _SectionHeader(
            title: 'Daily quests',
            trailing: controller.hasClaimableQuest ? 'Rewards ready' : null),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                children: quests
                    .map((quest) =>
                        QuestTile(controller: controller, quest: quest))
                    .toList()),
          ),
        ),
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.todayGoalProgress;
    final reached = controller.reachedDailyGoal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text('TODAY',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Palette.muted)),
              ),
              Text(
                reached
                    ? 'Goal reached!'
                    : '${controller.todayMinutes} / ${controller.dailyGoalMinutes} min',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: reached ? Palette.mint : Palette.muted,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: reached ? Palette.mint : null,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: .4),
                    ),
                  ),
                  Text('${(progress * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w900)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    _SummaryMetric(
                        value: formatMinutes(controller.todayMinutes),
                        label: 'Focus time'),
                    _SummaryMetric(
                        value: '${controller.todaySessionCount}',
                        label: 'Sessions'),
                    _SummaryMetric(
                        value: '${controller.coins}', label: 'Coins'),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(color: Palette.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PetPanel extends StatelessWidget {
  const _PetPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final working =
        controller.hasActiveSession && controller.pendingReward == null;
    final message = working
        ? '${controller.petName} is focusing with you.'
        : controller.todaySessionCount > 0
            ? '${controller.petName} is proud of today\'s work.'
            : controller.currentStreak > 0
                ? 'Keep your ${controller.currentStreak}-day streak alive!'
                : 'Complete one session to start your streak.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            PetIllustration(
                kind: controller.petKind,
                state: working ? PetState.focused : PetState.happy,
                size: 94,
                hat: controller.equipped[ItemCategory.hats],
                effect: controller.equipped[ItemCategory.effects]),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.petName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                  Text('Level ${controller.level}',
                      style: const TextStyle(color: Palette.muted)),
                  const SizedBox(height: 10),
                  Text(message,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestTile extends StatelessWidget {
  const QuestTile({required this.controller, required this.quest, super.key});
  final AppController controller;
  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    final color =
        quest.complete ? Palette.mint : Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
              quest.complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('+${quest.rewardCoins} coins  +${quest.rewardXp} XP',
                    style: const TextStyle(fontSize: 12, color: Palette.muted)),
              ],
            ),
          ),
          if (quest.complete && !quest.claimed)
            TextButton(
                onPressed: () => controller.claimQuest(quest),
                child: const Text('Claim'))
          else
            Text(quest.claimed ? 'Claimed' : '${quest.current}/${quest.target}',
                style: const TextStyle(
                    color: Palette.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  const _DailyPlanCard(
      {required this.controller, required this.onStartPlanItem});
  final AppController controller;
  final ValueChanged<DailyPlanItem> onStartPlanItem;

  @override
  Widget build(BuildContext context) {
    final plan = controller.dailyPlan;
    if (plan.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            const Text('Plan what you want to study today.',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Add a study block above or create tasks from an exam.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: plan.map((item) {
            final subject = controller.subjectById(item.subjectId);
            final task = controller.taskById(item.taskId);
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor:
                    Color(subject.colorValue).withValues(alpha: .16),
                child: Icon(_subjectIcon(subject),
                    color: Color(subject.colorValue)),
              ),
              title: Text(task?.title ?? subject.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${item.recommendedMinutes} min - ${item.reason}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton.filled(
                    tooltip: 'Start',
                    onPressed: () => onStartPlanItem(item),
                    icon: const Icon(Icons.play_arrow_rounded)),
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (action) async {
                    if (action == 'skip') {
                      await controller.skipPlanItem(item);
                    } else if (action == 'done' && task != null) {
                      await controller.markTaskDone(task);
                    } else if (action == 'edit' && task != null) {
                      if (context.mounted) {
                        await _showTaskEditor(context, controller, task: task);
                      }
                    } else if (action == 'delete' && task != null) {
                      if (context.mounted) {
                        await _confirmDeleteTask(context, controller, task);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (task != null)
                      const PopupMenuItem(
                          value: 'done', child: Text('Mark done')),
                    if (task != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'skip', child: Text('Skip today')),
                    if (task != null)
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                  ],
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

Future<void> _showTodayPlanEditor(
    BuildContext context, AppController controller) async {
  final title = TextEditingController();
  var subjectId = controller.subjects.first.id;
  var minutes = 25;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add to today\'s plan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 5),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('What do you want to study today?',
                  style: TextStyle(color: Palette.muted)),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: subjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: controller.subjects
                  .map((subject) => DropdownMenuItem(
                      value: subject.id, child: Text(subject.name)))
                  .toList(),
              onChanged: (value) => setLocal(() => subjectId = value!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Study block',
                  hintText: 'e.g. Practice quadratic equations'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Duration',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            const SizedBox(height: 9),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 15, label: Text('15 min')),
                ButtonSegment(value: 25, label: Text('25 min')),
                ButtonSegment(value: 45, label: Text('45 min')),
                ButtonSegment(value: 60, label: Text('60 min')),
              ],
              selected: {minutes},
              onSelectionChanged: (selection) =>
                  setLocal(() => minutes = selection.first),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (title.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Enter what you want to study first.')));
                      return;
                    }
                    await controller.addTask(
                      subjectId: subjectId,
                      title: title.text,
                      estimatedMinutes: minutes,
                      priority: TaskPriority.medium,
                      plannedDate: DateTime.now(),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Add to plan'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
  title.dispose();
}

class _ContinueTasksCard extends StatelessWidget {
  const _ContinueTasksCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tasks = controller.inProgressTasks.take(3).toList();
    return Card(
      color: Palette.mint.withValues(alpha: .1),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PICK UP WHERE YOU LEFT OFF',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Palette.muted)),
          const SizedBox(height: 4),
          ...tasks.map((task) {
            final subject = controller.subjectById(task.subjectId);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(Icons.play_circle_outline,
                  color: Color(subject.colorValue)),
              title: Text(task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${subject.name} - ${task.estimatedMinutes} min',
                  style: const TextStyle(color: Palette.muted)),
              trailing: TextButton(
                onPressed: () async {
                  await controller.startSession(
                    minutes: task.estimatedMinutes,
                    subjectId: task.subjectId,
                    taskId: task.id,
                    mode: FocusMode.normal,
                  );
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute<bool>(
                      builder: (_) =>
                          ActiveFocusScreen(controller: controller)));
                },
                child: const Text('Continue'),
              ),
            );
          }),
        ]),
      ),
    );
  }
}

class _UpcomingExamsCard extends StatelessWidget {
  const _UpcomingExamsCard({required this.controller, required this.exams});
  final AppController controller;
  final List<Exam> exams;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('UPCOMING EXAMS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Palette.muted)),
            const SizedBox(height: 6),
            ...exams.map((exam) {
              final subject = controller.subjectById(exam.subjectId);
              final timing =
                  exam.daysLeft == 0 ? 'Today' : '${exam.daysLeft} days left';
              final readiness = controller.examReadiness(exam);
              final readinessText =
                  readiness == null ? '' : ' - ${(readiness * 100).round()}% ready';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(Icons.event_note_outlined,
                    color: Color(subject.colorValue)),
                title: Text(exam.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${subject.name} - $timing$readinessText',
                    style: const TextStyle(color: Palette.muted)),
                trailing: Text(exam.importance.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              );
            }),
          ]),
        ),
      );
}

class _MistakeReviewPrompt extends StatelessWidget {
  const _MistakeReviewPrompt({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Palette.amber.withValues(alpha: .12),
      child: ListTile(
        leading:
            const Icon(Icons.lightbulb_outline_rounded, color: Palette.amber),
        title: Text(
            'Review ${controller.unresolvedMistakeCount} unresolved mistakes'),
        subtitle: const Text('Finding and fixing mistakes builds mastery.'),
        trailing: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Mistake review')),
              body: _MistakesTab(controller: controller),
            ),
          )),
          child: const Text('Review'),
        ),
      ),
    );
  }
}

class PlanScreen extends StatefulWidget {
  const PlanScreen(
      {required this.controller, required this.onStartTask, super.key});
  final AppController controller;
  final ValueChanged<StudyTask> onStartTask;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Study plan',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Organize what to study next.',
                  style: TextStyle(color: Palette.muted)),
              const SizedBox(height: 14),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Tasks')),
                  ButtonSegment(value: 1, label: Text('Subjects')),
                  ButtonSegment(value: 2, label: Text('Exams')),
                  ButtonSegment(value: 3, label: Text('Mistakes')),
                ],
                selected: {tab},
                onSelectionChanged: (value) =>
                    setState(() => tab = value.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (tab) {
            0 => _TasksTab(
                controller: widget.controller, onStartTask: widget.onStartTask),
            1 => _SubjectsTab(
                controller: widget.controller, onStartTask: widget.onStartTask),
            2 => _ExamsTab(controller: widget.controller),
            _ => _MistakesTab(controller: widget.controller),
          },
        ),
      ],
    );
  }
}

class _TasksTab extends StatefulWidget {
  const _TasksTab({required this.controller, required this.onStartTask});
  final AppController controller;
  final ValueChanged<StudyTask> onStartTask;

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  bool showAllDone = false;
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matches(StudyTask task) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (task.title.toLowerCase().contains(q)) return true;
    if (task.description.toLowerCase().contains(q)) return true;
    final subject = widget.controller.optionalSubject(task.subjectId);
    if (subject != null && subject.name.toLowerCase().contains(q)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final showSearch = controller.tasks.length >= 5;
    final open = controller.tasks
        .where((task) => task.status != TaskStatus.done && _matches(task))
        .toList()
      ..sort((a, b) {
        final priority = b.priority.index.compareTo(a.priority.index);
        if (priority != 0) return priority;
        return (a.dueDate ?? DateTime(2100))
            .compareTo(b.dueDate ?? DateTime(2100));
      });
    final done = controller.tasks
        .where((task) => task.status == TaskStatus.done && _matches(task))
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt)
          .compareTo(a.completedAt ?? a.createdAt));
    const collapsedCount = 5;
    final visibleDone =
        showAllDone || done.length <= collapsedCount ? done : done.take(collapsedCount).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      children: [
        _PlanTabHeader(
          title: 'Active tasks',
          subtitle: 'Turn your study goals into sessions.',
          buttonLabel: 'New task',
          icon: Icons.add_task_rounded,
          onPressed: () => _showTaskEditor(context, controller),
        ),
        if (showSearch) ...[
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => query = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => query = value.trim()),
          ),
        ],
        const SizedBox(height: 14),
        if (open.isEmpty)
          _EmptyPlanMessage(
            icon: Icons.task_alt_rounded,
            title: 'No active tasks',
            text: 'Add a concrete task and focus on what matters next.',
            actionLabel: 'Create task',
            onPressed: () => _showTaskEditor(context, controller),
          ),
        ...open.map((task) => _TaskTile(
            controller: controller,
            task: task,
            onStart: () => widget.onStartTask(task))),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Text('Completed (${done.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 17)),
            ),
            if (done.length > collapsedCount)
              TextButton(
                onPressed: () => setState(() => showAllDone = !showAllDone),
                child: Text(showAllDone ? 'Show less' : 'See all'),
              ),
          ]),
          const SizedBox(height: 8),
          ...visibleDone.map((task) =>
              _TaskTile(controller: controller, task: task, onStart: null)),
        ],
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(
      {required this.controller, required this.task, required this.onStart});
  final AppController controller;
  final StudyTask task;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final subject = controller.subjectById(task.subjectId);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 7,
                height: 38,
                decoration: BoxDecoration(
                    color: Color(subject.colorValue),
                    borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        '${subject.name} - ${task.estimatedMinutes} min - ${task.status.label}${task.dueDate == null ? '' : ' - due ${_shortDate(task.dueDate!)}'}',
                        style: const TextStyle(
                            fontSize: 12, color: Palette.muted)),
                  ]),
            ),
            _Badge(
                label: task.priority.label,
                color: task.priority == TaskPriority.high
                    ? Palette.coral
                    : Palette.primary),
            PopupMenuButton<String>(
              tooltip: 'Task options',
              onSelected: (action) async {
                if (action == 'edit') {
                  await _showTaskEditor(context, controller, task: task);
                } else if (action == 'delete') {
                  await _confirmDeleteTask(context, controller, task);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            if (onStart != null)
              Expanded(
                  child: FilledButton.tonalIcon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Focus'))),
            if (onStart != null) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: task.status == TaskStatus.done
                    ? null
                    : () async {
                        await controller.markTaskDone(task);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Task done. +${task.examId == null ? 20 : 30} XP, +5 coins'),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                icon: const Icon(Icons.check_rounded),
                label:
                    Text(task.status == TaskStatus.done ? 'Done' : 'Mark done'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({required this.controller, required this.onStartTask});
  final AppController controller;
  final ValueChanged<StudyTask> onStartTask;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      children: [
        _PlanTabHeader(
          title: 'Subjects',
          subtitle: 'Track weekly progress for each course.',
          buttonLabel: 'Add',
          icon: Icons.add_rounded,
          onPressed: () => _showSubjectEditor(context, controller),
        ),
        const SizedBox(height: 14),
        ...controller.subjects.map((subject) {
          final minutes = controller.weeklyMinutesForSubject(subject.id);
          final exam = controller.nextExamForSubject(subject.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SubjectDetailScreen(
                      controller: controller,
                      subject: subject,
                      onStartTask: onStartTask))),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(
                        backgroundColor:
                            Color(subject.colorValue).withValues(alpha: .15),
                        child: Icon(_subjectIcon(subject),
                            color: Color(subject.colorValue))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(subject.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16))),
                    Text('$minutes / ${subject.weeklyGoalMinutes} min',
                        style: const TextStyle(color: Palette.muted)),
                  ]),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                      value: (minutes / subject.weeklyGoalMinutes).clamp(0, 1),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(6),
                      color: Color(subject.colorValue)),
                  if (exam != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${exam.title} in ${exam.daysLeft} days',
                              style: const TextStyle(
                                  color: Palette.muted, fontSize: 12))),
                    ),
                ]),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ExamsTab extends StatelessWidget {
  const _ExamsTab({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final upcoming = controller.upcomingExams;
    final today = DateTime.now();
    final past = controller.exams
        .where((exam) =>
            DateTime(exam.examDate.year, exam.examDate.month, exam.examDate.day)
                .isBefore(DateTime(today.year, today.month, today.day)))
        .toList()
      ..sort((a, b) => b.examDate.compareTo(a.examDate));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      children: [
        _PlanTabHeader(
          title: 'Upcoming exams',
          subtitle: 'Add topics and create a preparation plan.',
          buttonLabel: 'New exam',
          icon: Icons.event_available_outlined,
          onPressed: () => _showExamEditor(context, controller),
        ),
        const SizedBox(height: 14),
        if (upcoming.isEmpty)
          _EmptyPlanMessage(
            icon: Icons.event_note_outlined,
            title: 'No upcoming exams',
            text: 'Add a test date and topics to build a study plan.',
            actionLabel: 'Add exam',
            onPressed: () => _showExamEditor(context, controller),
          ),
        ...upcoming.map((exam) {
          final subject = controller.subjectById(exam.subjectId);
          final planTasks =
              controller.tasks.where((task) => task.examId == exam.id).toList();
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(exam.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16))),
                      _Badge(
                          label: exam.importance.label,
                          color: exam.importance == ExamImportance.critical
                              ? Palette.coral
                              : Palette.amber),
                      PopupMenuButton<String>(
                        tooltip: 'Exam options',
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await _showExamEditor(context, controller,
                                exam: exam);
                          } else if (action == 'delete') {
                            await _confirmDeleteExam(context, controller, exam);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Edit exam')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete exam')),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Text(
                        '${subject.name} - ${_shortDate(exam.examDate)} - ${exam.daysLeft} days left',
                        style: const TextStyle(color: Palette.muted)),
                    const SizedBox(height: 8),
                    Text(
                        '${exam.topics.length} topics: ${exam.topics.join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (planTasks.isEmpty) ...[
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                          onPressed: () async {
                            await controller.generateTasksForExam(exam);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Study plan created below. Add blocks to today when ready.')));
                            }
                          },
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('Create study plan')),
                    ] else ...[
                      const SizedBox(height: 14),
                      Builder(builder: (context) {
                        final readiness = controller.examReadiness(exam) ?? 0.0;
                        final ready = readiness >= 1;
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Expanded(
                                    child: Text('Exam readiness',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13))),
                                Text(controller.examReadinessLabel(exam),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: ready
                                            ? Palette.mint
                                            : Color(subject.colorValue))),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                    value: readiness,
                                    minHeight: 7,
                                    color: ready
                                        ? Palette.mint
                                        : Color(subject.colorValue)),
                              ),
                            ]);
                      }),
                      const SizedBox(height: 14),
                      Text('Study plan (${planTasks.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13)),
                      const SizedBox(height: 6),
                      ...planTasks.map((task) {
                        final isToday = task.plannedDate != null &&
                            sameDay(task.plannedDate!, DateTime.now()) &&
                            task.status != TaskStatus.done;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 7),
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            Icon(
                                task.status == TaskStatus.done
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: task.status == TaskStatus.done
                                    ? Palette.mint
                                    : Palette.muted),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(
                                      '${task.estimatedMinutes} min - ${task.status.label}',
                                      style: const TextStyle(
                                          color: Palette.muted, fontSize: 12)),
                                ])),
                            if (task.status != TaskStatus.done)
                              TextButton(
                                onPressed: isToday
                                    ? null
                                    : () => controller.planTaskForToday(task),
                                child: Text(isToday ? 'Today' : 'Add today'),
                              ),
                          ]),
                        );
                      }),
                    ],
                  ]),
            ),
          );
        }),
        if (past.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Past exams',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 8),
          ...past.map((exam) {
            final subject = controller.subjectById(exam.subjectId);
            return Card(
              child: ListTile(
                title: Text(exam.title),
                subtitle:
                    Text('${subject.name} - ${_shortDate(exam.examDate)}'),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Exam options',
                  onSelected: (action) async {
                    if (action == 'delete') {
                      await _confirmDeleteExam(context, controller, exam);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete exam')),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

Future<void> _confirmDeleteExam(
    BuildContext context, AppController controller, Exam exam) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete exam?'),
      content: Text(
          'Remove "${exam.title}" and its generated study plan tasks? This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (delete != true) return;
  final deleted = await controller.deleteExam(exam);
  if (!deleted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Finish or cancel the active study session before deleting this exam.')));
  }
}

class _MistakesTab extends StatefulWidget {
  const _MistakesTab({required this.controller});
  final AppController controller;

  @override
  State<_MistakesTab> createState() => _MistakesTabState();
}

class _MistakesTabState extends State<_MistakesTab> {
  bool unresolvedOnly = true;
  String? subjectFilter;
  String? typeFilter;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _MistakesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final types = widget.controller.mistakes
        .map((mistake) => mistake.mistakeType)
        .toSet()
        .toList()
      ..sort();
    final items = widget.controller.mistakes
        .where((mistake) =>
            (!unresolvedOnly || !mistake.isResolved) &&
            (subjectFilter == null || mistake.subjectId == subjectFilter) &&
            (typeFilter == null || mistake.mistakeType == typeFilter))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
      children: [
        _PlanTabHeader(
          title: 'Mistake log',
          subtitle: 'Review errors and learn from them.',
          buttonLabel: 'Add',
          icon: Icons.add_rounded,
          onPressed: () => showAddMistake(context, widget.controller),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Unresolved only'),
          value: unresolvedOnly,
          onChanged: (value) => setState(() => unresolvedOnly = value),
        ),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: subjectFilter,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...widget.controller.subjects.map((subject) => DropdownMenuItem(
                    value: subject.id, child: Text(subject.name))),
              ],
              onChanged: (value) => setState(() => subjectFilter = value),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: typeFilter,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...types.map(
                    (type) => DropdownMenuItem(value: type, child: Text(type))),
              ],
              onChanged: (value) => setState(() => typeFilter = value),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _EmptyPlanMessage(
            icon: Icons.lightbulb_outline_rounded,
            title: 'No mistakes to review',
            text: 'Logging mistakes turns confusion into progress.',
            actionLabel: 'Log mistake',
            onPressed: () => showAddMistake(context, widget.controller),
          ),
        ...items.map((mistake) {
          final subject = widget.controller.subjectById(mistake.subjectId);
          return Card(
            margin: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              onTap: () =>
                  _showMistakeDetail(context, widget.controller, mistake),
              title: Text(mistake.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                  '${subject.name} - ${mistake.mistakeType} - ${_shortDate(mistake.createdAt)}'),
              trailing: mistake.isResolved
                  ? const Icon(Icons.check_circle, color: Palette.mint)
                  : TextButton(
                      onPressed: () => widget.controller.reviewMistake(mistake),
                      child: const Text('Review')),
            ),
          );
        }),
      ],
    );
  }
}

Future<void> _showMistakeDetail(
    BuildContext context, AppController controller, Mistake mistake) async {
  final subject = controller.subjectById(mistake.subjectId);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 4, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mistake.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                  '${subject.name} - ${mistake.mistakeType} - ${_shortDate(mistake.createdAt)}',
                  style: const TextStyle(color: Palette.muted)),
              if (mistake.isResolved && mistake.reviewedAt != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.check_circle, color: Palette.mint, size: 16),
                  const SizedBox(width: 6),
                  Text('Reviewed ${_shortDate(mistake.reviewedAt!)}',
                      style: const TextStyle(
                          color: Palette.mint, fontWeight: FontWeight.w700)),
                ]),
              ],
              if (mistake.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('What happened',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Palette.muted)),
                const SizedBox(height: 4),
                Text(mistake.description, style: const TextStyle(height: 1.4)),
              ],
              if (mistake.correction.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Correct approach',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: Palette.muted)),
                const SizedBox(height: 4),
                Text(mistake.correction, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 22),
              if (mistake.isResolved)
                OutlinedButton.icon(
                  onPressed: () => controller.reopenMistake(mistake),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reopen for review'),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    await controller.reviewMistake(mistake);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark reviewed  (+10 XP)'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PlanTabHeader extends StatelessWidget {
  const _PlanTabHeader({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 3),
              Text(subtitle,
                  maxLines: 2,
                  style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(buttonLabel),
          ),
        ],
      );
}

class _EmptyPlanMessage extends StatelessWidget {
  const _EmptyPlanMessage({
    required this.icon,
    required this.title,
    required this.text,
    required this.actionLabel,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String text;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.muted, height: 1.35)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ),
          ]),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      );
}

class SubjectDetailScreen extends StatefulWidget {
  const SubjectDetailScreen(
      {required this.controller,
      required this.subject,
      required this.onStartTask,
      super.key});
  final AppController controller;
  final Subject subject;
  final ValueChanged<StudyTask> onStartTask;

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  AppController get controller => widget.controller;
  Subject get subject => widget.subject;
  ValueChanged<StudyTask> get onStartTask => widget.onStartTask;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks =
        controller.tasks.where((task) => task.subjectId == subject.id).toList();
    final exams =
        controller.exams.where((exam) => exam.subjectId == subject.id).toList();
    final mistakes = controller.mistakes
        .where((mistake) => mistake.subjectId == subject.id)
        .toList();
    final minutes = controller.weeklyMinutesForSubject(subject.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        actions: [
          IconButton(
              tooltip: 'Edit subject',
              onPressed: () =>
                  _showSubjectEditor(context, controller, subject: subject),
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
              tooltip: 'Delete subject',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete subject?'),
                    content: Text(
                        'Remove "${subject.name}"? Subjects with study data cannot be deleted.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                final deleted = await controller.deleteSubject(subject);
                if (!context.mounted) return;
                if (deleted) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'A subject with study data cannot be deleted.')));
                }
              },
              icon: const Icon(Icons.delete_outline))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Weekly goal: $minutes / ${subject.weeklyGoalMinutes} min',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                        value:
                            (minutes / subject.weeklyGoalMinutes).clamp(0, 1),
                        minHeight: 8,
                        color: Color(subject.colorValue)),
                  ]),
            ),
          ),
          if (controller.subjectAccuracy(subject.id) != null ||
              controller.subjectAvgConfidence(subject.id) != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  if (controller.subjectAccuracy(subject.id) != null)
                    _PetMetric(
                        label: 'Accuracy',
                        value:
                            '${(controller.subjectAccuracy(subject.id)! * 100).round()}%'),
                  if (controller.subjectAvgConfidence(subject.id) != null)
                    _PetMetric(
                        label: 'Avg confidence',
                        value:
                            '${controller.subjectAvgConfidence(subject.id)!.toStringAsFixed(1)} / 5'),
                  _PetMetric(
                      label: 'This week', value: formatMinutes(minutes)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 15),
          FilledButton.icon(
              onPressed: () async {
                await controller.startSession(
                    minutes: 25, subjectId: subject.id, mode: FocusMode.normal);
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ActiveFocusScreen(controller: controller)));
                }
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Start Focus for ${subject.name}')),
          const SizedBox(height: 22),
          Row(children: [
            const Expanded(child: _SectionHeader(title: 'Active tasks')),
            TextButton.icon(
                onPressed: () =>
                    _showTaskEditor(context, controller, subjectId: subject.id),
                icon: const Icon(Icons.add),
                label: const Text('Add'))
          ]),
          ...tasks.where((task) => task.status != TaskStatus.done).map((task) =>
              _TaskTile(
                  controller: controller,
                  task: task,
                  onStart: () => onStartTask(task))),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Exams'),
          const SizedBox(height: 8),
          ...exams.map((exam) => ListTile(
              title: Text(exam.title),
              subtitle: Text(
                  '${_shortDate(exam.examDate)} - ${exam.daysLeft} days left'))),
          const SizedBox(height: 12),
          const _SectionHeader(title: 'Mistake log'),
          const SizedBox(height: 8),
          ...mistakes.map((mistake) => ListTile(
              onTap: () => _showMistakeDetail(context, controller, mistake),
              title: Text(mistake.title),
              subtitle: Text(mistake.mistakeType),
              trailing: mistake.isResolved
                  ? const Icon(Icons.check_circle, color: Palette.mint)
                  : null)),
        ],
      ),
    );
  }
}

Future<void> _showSubjectEditor(BuildContext context, AppController controller,
    {Subject? subject}) async {
  final name = TextEditingController(text: subject?.name);
  var goal = subject?.weeklyGoalMinutes ?? 90;
  var color = subject?.colorValue ?? Palette.primary.toARGB32();
  var icon = subject?.iconCodePoint ?? Icons.book_outlined.codePoint;
  const colors = [0xFF4E68D8, 0xFF47C3A4, 0xFFFF8068, 0xFFFFC24C, 0xFF8896A8];
  const icons = [
    Icons.book_outlined,
    Icons.calculate_outlined,
    Icons.code_rounded,
    Icons.language_outlined,
    Icons.science_outlined,
  ];
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) {
            return AlertDialog(
              title: Text(subject == null ? 'New subject' : 'Edit subject'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 14),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Wrap(
                      children: colors
                          .map((value) => IconButton(
                              onPressed: () => setLocal(() => color = value),
                              icon: Icon(
                                  color == value
                                      ? Icons.check_circle
                                      : Icons.circle,
                                  color: Color(value))))
                          .toList()),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Icon',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Wrap(
                      children: icons
                          .map((value) => IconButton(
                              onPressed: () =>
                                  setLocal(() => icon = value.codePoint),
                              icon: Icon(value,
                                  color: icon == value.codePoint
                                      ? Theme.of(context).colorScheme.primary
                                      : Palette.muted)))
                          .toList()),
                  Row(children: [
                    const Expanded(child: Text('Weekly goal')),
                    IconButton(
                        onPressed: () =>
                            setLocal(() => goal = math.max(30, goal - 30)),
                        icon: const Icon(Icons.remove)),
                    Text('$goal min'),
                    IconButton(
                        onPressed: () => setLocal(() => goal += 30),
                        icon: const Icon(Icons.add)),
                  ]),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Enter a subject name first.')));
                        return;
                      }
                      if (subject == null) {
                        await controller.addSubject(
                            name: name.text,
                            colorValue: color,
                            iconCodePoint: icon,
                            weeklyGoalMinutes: goal);
                      } else {
                        subject.name = name.text.trim();
                        subject.colorValue = color;
                        subject.iconCodePoint = icon;
                        subject.weeklyGoalMinutes = goal;
                        await controller.updateSubject(subject);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'))
              ],
            );
          }));
  name.dispose();
}

Future<void> _showTaskEditor(BuildContext context, AppController controller,
    {String? subjectId, StudyTask? task}) async {
  final title = TextEditingController(text: task?.title);
  final description = TextEditingController(text: task?.description);
  var selectedSubject =
      subjectId ?? task?.subjectId ?? controller.subjects.first.id;
  var minutes = task?.estimatedMinutes ?? 25;
  var priority = task?.priority ?? TaskPriority.medium;
  var dueDate = task?.dueDate;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) {
            return AlertDialog(
              title: Text(task == null ? 'New study task' : 'Edit study task'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: controller.subjects
                          .map((item) => DropdownMenuItem(
                              value: item.id, child: Text(item.name)))
                          .toList(),
                      onChanged: (value) =>
                          setLocal(() => selectedSubject = value!)),
                  TextField(
                      controller: title,
                      decoration:
                          const InputDecoration(labelText: 'Task title')),
                  TextField(
                      controller: description,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2),
                  DropdownButtonFormField<TaskPriority>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.values
                          .map((item) => DropdownMenuItem(
                              value: item, child: Text(item.label)))
                          .toList(),
                      onChanged: (value) => setLocal(() => priority = value!)),
                  Row(children: [
                    const Expanded(child: Text('Estimated time')),
                    IconButton(
                        onPressed: () =>
                            setLocal(() => minutes = math.max(5, minutes - 5)),
                        icon: const Icon(Icons.remove)),
                    Text('$minutes min'),
                    IconButton(
                        onPressed: () => setLocal(() => minutes += 5),
                        icon: const Icon(Icons.add)),
                  ]),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dueDate == null
                          ? 'No due date'
                          : 'Due ${_shortDate(dueDate!)}'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            initialDate: dueDate ?? DateTime.now());
                        if (date != null) setLocal(() => dueDate = date);
                      }),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Enter a task title first.')));
                        return;
                      }
                      if (task == null) {
                        await controller.addTask(
                            subjectId: selectedSubject,
                            title: title.text,
                            description: description.text,
                            estimatedMinutes: minutes,
                            priority: priority,
                            dueDate: dueDate);
                      } else {
                        task.subjectId = selectedSubject;
                        task.title = title.text.trim();
                        task.description = description.text.trim();
                        task.estimatedMinutes = minutes;
                        task.priority = priority;
                        task.dueDate = dueDate;
                        await controller.updateTask(task);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(task == null ? 'Save' : 'Update'))
              ],
            );
          }));
  title.dispose();
  description.dispose();
}

Future<void> _confirmDeleteTask(
    BuildContext context, AppController controller, StudyTask task) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text('Remove "${task.title}" from your study plan?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (delete != true) return;
  final deleted = await controller.deleteTask(task);
  if (!deleted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A task in an active session cannot be deleted.')));
  }
}

Future<void> _showExamEditor(BuildContext context, AppController controller,
    {Exam? exam}) async {
  final title = TextEditingController(text: exam?.title);
  final topics = TextEditingController(text: exam?.topics.join(', '));
  var subjectId = exam?.subjectId ?? controller.subjects.first.id;
  var date = exam?.examDate ?? DateTime.now().add(const Duration(days: 7));
  var importance = exam?.importance ?? ExamImportance.important;
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) {
            return AlertDialog(
              title: Text(exam == null ? 'Add exam' : 'Edit exam'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                      initialValue: subjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: controller.subjects
                          .map((item) => DropdownMenuItem(
                              value: item.id, child: Text(item.name)))
                          .toList(),
                      // Subject is fixed once an exam exists so generated study
                      // tasks stay consistent with their subject.
                      onChanged: exam != null
                          ? null
                          : (value) => setLocal(() => subjectId = value!)),
                  TextField(
                      controller: title,
                      decoration:
                          const InputDecoration(labelText: 'Exam title')),
                  TextField(
                      controller: topics,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Topics (comma separated)')),
                  DropdownButtonFormField<ExamImportance>(
                      initialValue: importance,
                      decoration:
                          const InputDecoration(labelText: 'Importance'),
                      items: ExamImportance.values
                          .map((item) => DropdownMenuItem(
                              value: item, child: Text(item.label)))
                          .toList(),
                      onChanged: (value) =>
                          setLocal(() => importance = value!)),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${_shortDate(date)}'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final selected = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 730)),
                            initialDate: date);
                        if (selected != null) setLocal(() => date = selected);
                      }),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Enter an exam title first.')));
                        return;
                      }
                      final parsedTopics = topics.text
                          .split(',')
                          .map((text) => text.trim())
                          .toList();
                      if (exam == null) {
                        await controller.addExam(
                            subjectId: subjectId,
                            title: title.text,
                            examDate: date,
                            topics: parsedTopics,
                            importance: importance);
                      } else {
                        await controller.updateExam(exam,
                            title: title.text,
                            examDate: date,
                            topics: parsedTopics,
                            importance: importance);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save'))
              ],
            );
          }));
  title.dispose();
  topics.dispose();
}

Future<void> showAddMistake(BuildContext context, AppController controller,
    {String? subjectId, String? taskId, String? sessionId}) async {
  final title = TextEditingController();
  final description = TextEditingController();
  final correction = TextEditingController();
  var selectedSubject = subjectId ?? controller.subjects.first.id;
  var type = 'Careless mistake';
  const types = [
    'Careless mistake',
    'Formula mistake',
    'Forgot rule',
    'Calculation error',
    'Grammar mistake',
    'Syntax error',
    'Misunderstood task'
  ];
  await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Add mistake'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: controller.subjects
                          .map((item) => DropdownMenuItem(
                              value: item.id, child: Text(item.name)))
                          .toList(),
                      onChanged: (value) =>
                          setLocal(() => selectedSubject = value!)),
                  DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: types
                          .map((item) =>
                              DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) => setLocal(() => type = value!)),
                  TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: description,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'What went wrong?')),
                  TextField(
                      controller: correction,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Correct solution / note')),
                ]),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () async {
                      if (title.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Enter a mistake title first.')));
                        return;
                      }
                      await controller.addMistake(
                          subjectId: selectedSubject,
                          taskId: taskId,
                          sessionId: sessionId,
                          title: title.text,
                          description: description.text,
                          mistakeType: type,
                          correction: correction.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Good job. Finding mistakes is part of learning. +5 XP')));
                      }
                    },
                    child: const Text('Save'))
              ],
            );
          }));
  title.dispose();
  description.dispose();
  correction.dispose();
}

String _shortDate(DateTime date) {
  final now = DateTime.now();
  final y = date.year != now.year ? '/${date.year}' : '';
  return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}$y';
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

IconData _subjectIcon(Subject subject) {
  if (subject.iconCodePoint == Icons.calculate_outlined.codePoint) {
    return Icons.calculate_outlined;
  }
  if (subject.iconCodePoint == Icons.code_rounded.codePoint) {
    return Icons.code_rounded;
  }
  if (subject.iconCodePoint == Icons.language_outlined.codePoint) {
    return Icons.language_outlined;
  }
  if (subject.iconCodePoint == Icons.science_outlined.codePoint) {
    return Icons.science_outlined;
  }
  return Icons.book_outlined;
}

class FocusSetupScreen extends StatefulWidget {
  const FocusSetupScreen(
      {required this.controller, required this.onStarted, super.key});

  final AppController controller;
  final VoidCallback onStarted;

  @override
  State<FocusSetupScreen> createState() => _FocusSetupScreenState();
}

class _FocusSetupScreenState extends State<FocusSetupScreen> {
  int selectedMinutes = 25;
  late String subjectId;
  FocusMode mode = FocusMode.normal;

  @override
  void initState() {
    super.initState();
    subjectId = widget.controller.subjects.first.id;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.subjects.any((subject) => subject.id == subjectId)) {
      subjectId = widget.controller.subjects.first.id;
    }
    if (widget.controller.hasActiveSession) {
      final active = widget.controller.activeSession!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PetIllustration(
                  kind: widget.controller.petKind,
                  state: PetState.focused,
                  size: 120),
              const SizedBox(height: 20),
              Text(
                widget.controller.pendingReward == null
                    ? 'Session in progress'
                    : 'Session complete',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text('${active.subject} - ${active.mode.label}',
                  style: const TextStyle(color: Palette.muted, fontSize: 16)),
              const SizedBox(height: 25),
              FilledButton.icon(
                onPressed: widget.onStarted,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(widget.controller.pendingReward == null
                    ? 'Open timer'
                    : 'View reward'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Choose your session',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Small steps build strong habits.',
            style: TextStyle(color: Palette.muted)),
        const SizedBox(height: 28),
        const _SectionHeader(title: 'Focus time'),
        const SizedBox(height: 10),
        Row(
          children: [15, 25, 45, 60].map((value) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SelectTile(
                  title: '$value',
                  subtitle: 'min',
                  selected: selectedMinutes == value,
                  onTap: () => setState(() => selectedMinutes = value),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                    child: Text('Custom time',
                        style: TextStyle(fontWeight: FontWeight.w800))),
                IconButton(
                  tooltip: 'Reduce time',
                  onPressed: () => setState(
                      () => selectedMinutes = math.max(5, selectedMinutes - 5)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                    width: 56,
                    child: Text('$selectedMinutes m',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                IconButton(
                  tooltip: 'Add time',
                  onPressed: () => setState(() =>
                      selectedMinutes = math.min(180, selectedMinutes + 5)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        const _SectionHeader(title: 'Mode'),
        const SizedBox(height: 10),
        ...FocusMode.values.map(
          (value) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ModeTile(
              mode: value,
              selected: mode == value,
              onTap: () => setState(() => mode = value),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'Subject'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.controller.subjects.map(
              (value) {
                final selected = subjectId == value.id;
                final scheme = Theme.of(context).colorScheme;
                return ChoiceChip(
                  label: Text(value.name),
                  selected: selected,
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.primary.withValues(alpha: .16),
                  labelStyle: TextStyle(
                    color: selected ? scheme.primary : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  checkmarkColor: scheme.primary,
                  side: BorderSide(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                  ),
                  onSelected: (_) => setState(() => subjectId = value.id),
                );
              },
            ),
            ActionChip(
              backgroundColor: Theme.of(context).colorScheme.surface,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
              avatar: Icon(Icons.add,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              label: const Text('Add'),
              onPressed: () => _addSubject(context),
            ),
          ],
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: () async {
            final started = await widget.controller.startSession(
                minutes: selectedMinutes, subjectId: subjectId, mode: mode);
            if (started || widget.controller.hasActiveSession) {
              widget.onStarted();
            }
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Focus'),
        ),
      ],
    );
  }

  Future<void> _addSubject(BuildContext context) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add subject'),
        content: TextField(
            controller: input,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Biology')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, input.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    input.dispose();
    if (value != null && value.isNotEmpty) {
      await widget.controller.addSubject(
          name: value,
          colorValue: Palette.primary.toARGB32(),
          iconCodePoint: Icons.book_outlined.codePoint,
          weeklyGoalMinutes: 90);
      setState(() => subjectId = widget.controller.subjects.last.id);
    }
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile(
      {required this.title,
      required this.subtitle,
      required this.selected,
      required this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w900)),
              Text(subtitle,
                  style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile(
      {required this.mode, required this.selected, required this.onTap});
  final FocusMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      FocusMode.normal => Icons.timer_outlined,
      FocusMode.pomodoro => Icons.coffee_outlined,
      FocusMode.deep => Icons.shield_outlined,
    };
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.label,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(mode.description,
                        style: const TextStyle(
                            color: Palette.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveFocusScreen extends StatefulWidget {
  const ActiveFocusScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<ActiveFocusScreen> createState() => _ActiveFocusScreenState();
}

class _ActiveFocusScreenState extends State<ActiveFocusScreen> {
  Timer? ticker;
  bool closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_closeIfSessionEnded);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_closeIfSessionEnded);
    ticker?.cancel();
    super.dispose();
  }

  void _closeIfSessionEnded() {
    if (widget.controller.activeSession == null) {
      _leaveTimer(true);
    }
  }

  void _leaveTimer([bool completed = false]) {
    if (closing || !mounted) return;
    closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(completed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.controller.activeSession;
    if (active == null) {
      _leaveTimer();
      return const Scaffold(body: SizedBox.shrink());
    }
    final seconds = active.remainingSeconds();
    if (seconds <= 0) {
      return SessionCompleteView(
          controller: widget.controller, session: active);
    }
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    final progress = 1 - seconds / (active.durationMinutes * 60);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded)),
                          Expanded(
                              child: Text(active.mode.label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900))),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 270,
                        width: 270,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: progress.clamp(0, 1),
                                strokeWidth: 13,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: .45),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(time,
                                    style: const TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 7),
                                Text(active.subject,
                                    style: const TextStyle(
                                        color: Palette.muted,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      PetIllustration(
                          kind: widget.controller.petKind,
                          state: active.isPaused
                              ? PetState.sleepy
                              : PetState.focused,
                          size: 110),
                      const SizedBox(height: 14),
                      Text(
                        active.isPaused
                            ? 'Paused - ${3 - active.pauseCount} pauses left this session.'
                            : '${widget.controller.petName} is focusing too.',
                        style:
                            const TextStyle(color: Palette.muted, fontSize: 16),
                      ),
                      const Spacer(),
                      if (active.mode == FocusMode.deep)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 13),
                          child: Text(
                              'Deep Focus gives higher rewards when you finish.',
                              style: TextStyle(
                                  fontSize: 12, color: Palette.muted)),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: active.isPaused ||
                                      active.pauseCount < 3
                                  ? () async {
                                      if (active.isPaused) {
                                        await widget.controller.resumeSession();
                                      } else {
                                        await widget.controller.pauseSession();
                                      }
                                      setState(() {});
                                    }
                                  : null,
                              icon: Icon(active.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded),
                              label: Text(active.isPaused ? 'Resume' : 'Pause'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error),
                              onPressed: () => _cancel(context),
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: const Text('The reward for this session will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep focusing')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (cancel == true && context.mounted) {
      Navigator.pop(context);
      await widget.controller.cancelSession();
    }
  }
}

class SessionCompleteView extends StatefulWidget {
  const SessionCompleteView(
      {required this.controller, required this.session, super.key});
  final AppController controller;
  final ActiveSession session;

  @override
  State<SessionCompleteView> createState() => _SessionCompleteViewState();
}

class _SessionCompleteViewState extends State<SessionCompleteView> {
  int exercises = 0;
  int correct = 0;
  int confidence = 3;
  bool markTaskDone = true;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward =
        calculateReward(widget.session.durationMinutes, widget.session.mode);
    final linkedTask = widget.controller.taskById(widget.session.taskId);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 18),
            Center(
              child: PetIllustration(
                  kind: widget.controller.petKind,
                  state: PetState.proud,
                  size: 118),
            ),
            const SizedBox(height: 18),
            Text('Great job!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('You focused for ${widget.session.durationMinutes} minutes.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.muted, fontSize: 16)),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RewardLine(
                        icon: Icons.bolt_rounded, title: '+${reward.xp} XP'),
                    _RewardLine(
                        icon: Icons.monetization_on_outlined,
                        title: '+${reward.coins}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SectionHeader(title: 'What did you accomplish?'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    if (linkedTask != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: markTaskDone,
                        onChanged: (value) =>
                            setState(() => markTaskDone = value ?? false),
                        title: Text('Completed: ${linkedTask.title}'),
                        subtitle: const Text('Mark task done for bonus XP'),
                      ),
                    _ResultStepper(
                        label: 'Exercises solved',
                        value: exercises,
                        onChanged: (value) => setState(() {
                              exercises = value;
                              // Keep correct answers within the new total so we
                              // never store correct > exercises.
                              if (correct > exercises) correct = exercises;
                            })),
                    _ResultStepper(
                        label: 'Correct answers',
                        value: correct,
                        maximum: exercises,
                        onChanged: (value) => setState(() => correct = value)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Expanded(
                          child: Text('Confidence',
                              style: TextStyle(fontWeight: FontWeight.w700))),
                      ...List.generate(
                          5,
                          (index) => Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ChoiceChip(
                                    label: Text('${index + 1}'),
                                    selected: confidence == index + 1,
                                    onSelected: (_) =>
                                        setState(() => confidence = index + 1)),
                              )),
                    ]),
                    TextField(
                      controller: note,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'Still confused about factoring.'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showAddMistake(
                context,
                widget.controller,
                subjectId: widget.session.subjectId,
                taskId: widget.session.taskId,
                sessionId: widget.session.id,
              ),
              icon: const Icon(Icons.error_outline),
              label: const Text('Add mistake'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final completed = await widget.controller.claimCompletedSession(
                    markTaskDone: markTaskDone,
                    exercisesSolved: exercises,
                    correctAnswers: correct,
                    confidenceLevel: confidence,
                    note: note.text);
                if (widget.controller.vibrationEnabled) {
                  await HapticFeedback.mediumImpact();
                }
                if (context.mounted && completed != null) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save result and claim rewards'),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _ResultStepper extends StatelessWidget {
  const _ResultStepper(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.maximum = 99});
  final String label;
  final int value;
  final int maximum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline)),
        SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800))),
        IconButton(
            onPressed: value < maximum ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))
        ]),
      );
}

class PetScreen extends StatelessWidget {
  const PetScreen({required this.controller, super.key});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.petName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text(
                      '${controller.petKind.label} - Level ${controller.level}',
                      style: const TextStyle(color: Palette.muted)),
                ],
              ),
            ),
            _Pill(
                icon: Icons.monetization_on_outlined,
                value: '${controller.coins}',
                color: Palette.amber),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: controller.levelProgress, minHeight: 10),
        ),
        const SizedBox(height: 7),
        Text(
            '${controller.xpIntoLevel} / ${controller.xpForNextLevel} XP until Level ${controller.level + 1}',
            style: const TextStyle(color: Palette.muted, fontSize: 12)),
        const SizedBox(height: 34),
        _PetHabitat(controller: controller),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _PetMetric(
                    label: 'Mood',
                    value:
                        controller.todaySessionCount > 0 ? 'Proud' : 'Happy'),
                _PetMetric(
                    label: 'Focus time',
                    value: formatMinutes(controller.totalMinutes)),
                _PetMetric(
                    label: 'Sessions', value: '${controller.sessions.length}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.canFeedPet
                    ? () async {
                        final fed = await controller.feedPet();
                        if (!context.mounted) return;
                        final message = fed
                            ? '${controller.petName} enjoyed a snack. -10 coins, +5 XP'
                            : 'Could not feed ${controller.petName} right now.';
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(message)));
                      }
                    : null,
                icon: const Icon(Icons.restaurant_outlined),
                label: Text(controller.coins < 10 ? 'Feed (10 coins)' : 'Feed'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => _rename(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Rename')),
            ),
          ],
        ),
        if (!controller.canFeedPet && controller.coins >= 10) ...[
          const SizedBox(height: 6),
          Text('${controller.petName} is full — you can feed again later.',
              style: const TextStyle(color: Palette.muted, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ShopScreen(controller: controller),
          )),
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Customize and shop'),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'Equipped items'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: ItemCategory.values.map((category) {
                final itemId = controller.equipped[category];
                final item = itemId == null
                    ? null
                    : shopCatalog
                        .firstWhere((candidate) => candidate.id == itemId);
                return _StatRow(
                    label: category.label, value: item?.name ?? 'None');
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final input = TextEditingController(text: controller.petName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename your buddy'),
        content: TextField(controller: input, autofocus: true, maxLength: 16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, input.text),
              child: const Text('Save')),
        ],
      ),
    );
    input.dispose();
    if (name != null) await controller.renamePet(name);
  }
}

class _PetMetric extends StatelessWidget {
  const _PetMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Palette.muted, fontSize: 12)),
          ],
        ),
      );
}

class _PetHabitat extends StatelessWidget {
  const _PetHabitat({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final background = controller.equipped[ItemCategory.backgrounds];
    final roomItem = controller.equipped[ItemCategory.room];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 256,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter:
                    _HabitatPainter(background: background, roomItem: roomItem),
              ),
            ),
            PetIllustration(
                kind: controller.petKind,
                state: controller.todaySessionCount > 0
                    ? PetState.proud
                    : PetState.happy,
                size: 196,
                hat: controller.equipped[ItemCategory.hats],
                effect: controller.equipped[ItemCategory.effects]),
          ],
        ),
      ),
    );
  }
}

class _HabitatPainter extends CustomPainter {
  const _HabitatPainter({this.background, this.roomItem, this.compact = false});
  final String? background;
  final String? roomItem;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final scale = size.width / (compact ? 58 : 340);
    final floorY = size.height * .8;
    final colors = switch (background) {
      'library' => [const Color(0xFFFFF4D9), const Color(0xFFFFE3B5)],
      'space' => [const Color(0xFF152444), const Color(0xFF2C4274)],
      _ => [const Color(0xFFF1F7F3), const Color(0xFFE4F0EC)],
    };
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    if (background == 'space') {
      paint.color = const Color(0xFFFFE7A1);
      for (final point in const [
        Offset(.14, .2),
        Offset(.3, .12),
        Offset(.76, .18),
        Offset(.88, .34),
        Offset(.19, .45)
      ]) {
        canvas.drawCircle(Offset(size.width * point.dx, size.height * point.dy),
            (compact ? 1.2 : 2.2) * scale, paint);
      }
      paint.color = const Color(0xFFFFEFBA);
      canvas.drawCircle(Offset(size.width * .78, size.height * .24),
          (compact ? 7 : 17) * scale, paint);
    }

    if (background == 'library') {
      _drawShelf(canvas, size, paint, size.width * .045, size.height * .18,
          size.width * .2, size.height * .58);
      _drawShelf(canvas, size, paint, size.width * .77, size.height * .14,
          size.width * .185, size.height * .62);
    }

    paint.color = background == 'space'
        ? const Color(0xFF101B37)
        : const Color(0xFFD5C09F)
            .withValues(alpha: background == null ? .18 : 1);
    canvas.drawRect(
        Rect.fromLTWH(0, floorY, size.width, size.height - floorY), paint);
    paint.color = background == 'space'
        ? const Color(0xFF3D568D)
        : const Color(0xFFC8B18B)
            .withValues(alpha: background == null ? .3 : 1);
    canvas.drawRect(Rect.fromLTWH(0, floorY, size.width, 2 * scale), paint);

    switch (roomItem) {
      case 'lamp':
        _drawLamp(canvas, size, paint);
      case 'plant':
        _drawPlant(canvas, size, paint);
      case 'bookshelf':
        _drawShelf(canvas, size, paint, size.width * .77, size.height * .42,
            size.width * .19, size.height * .4);
    }
  }

  void _drawLamp(Canvas canvas, Size size, Paint paint) {
    final s = size.width / (compact ? 58 : 340);
    final x = size.width * .84;
    final baseY = size.height * .84;
    paint.color = const Color(0xFFF7D774).withValues(alpha: .24);
    canvas.drawCircle(Offset(x - 11 * s, baseY - 52 * s), 30 * s, paint);
    paint.color = const Color(0xFF354666);
    paint.strokeWidth = 3 * s;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(x, baseY - 7 * s), Offset(x - 9 * s, baseY - 45 * s), paint);
    canvas.drawLine(Offset(x - 9 * s, baseY - 45 * s),
        Offset(x - 27 * s, baseY - 57 * s), paint);
    paint.color = const Color(0xFFFFD36A);
    final shade = Path()
      ..moveTo(x - 38 * s, baseY - 60 * s)
      ..lineTo(x - 20 * s, baseY - 70 * s)
      ..lineTo(x - 12 * s, baseY - 53 * s)
      ..lineTo(x - 31 * s, baseY - 49 * s)
      ..close();
    canvas.drawPath(shade, paint);
    paint.color = const Color(0xFF354666);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, baseY), width: 28 * s, height: 6 * s),
        paint);
  }

  void _drawPlant(Canvas canvas, Size size, Paint paint) {
    final s = size.width / (compact ? 58 : 340);
    final x = size.width * .84;
    final y = size.height * .84;
    paint.color = const Color(0xFFC97854);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 17 * s, y - 25 * s, 34 * s, 25 * s),
          Radius.circular(5 * s)),
      paint,
    );
    paint.color = const Color(0xFF3C9B73);
    for (final leaf in [
      Rect.fromLTWH(x - 30 * s, y - 62 * s, 25 * s, 17 * s),
      Rect.fromLTWH(x - 4 * s, y - 70 * s, 22 * s, 28 * s),
      Rect.fromLTWH(x + 4 * s, y - 50 * s, 28 * s, 16 * s),
    ]) {
      canvas.drawOval(leaf, paint);
    }
  }

  void _drawShelf(Canvas canvas, Size size, Paint paint, double x, double y,
      double width, double height) {
    paint.color = const Color(0xFF79533C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, width, height), Radius.circular(width * .06)),
      paint,
    );
    final shelf = height / 3;
    final bookColors = [
      const Color(0xFFE66E58),
      const Color(0xFF4E68D8),
      const Color(0xFF47C3A4),
      const Color(0xFFFFC24C),
    ];
    for (var row = 0; row < 3; row++) {
      paint.color = const Color(0xFFA97B55);
      canvas.drawRect(
          Rect.fromLTWH(x, y + shelf * (row + 1) - 2, width, 3), paint);
      for (var index = 0; index < 3; index++) {
        paint.color = bookColors[(row + index) % bookColors.length];
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + width * (.12 + index * .24),
                y + shelf * row + shelf * .2, width * .16, shelf * .57),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HabitatPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.roomItem != roomItem ||
      oldDelegate.compact != compact;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final subjectData = controller.subjectMinutes;
    final subjectTotal =
        math.max(1, subjectData.values.fold(0, (sum, value) => sum + value));
    final doneTasks =
        controller.tasks.where((task) => task.status == TaskStatus.done).length;
    final activeTasks =
        controller.tasks.where((task) => task.status != TaskStatus.done).length;
    final mistakeTypes = <String, int>{};
    for (final mistake in controller.mistakes) {
      mistakeTypes.update(mistake.mistakeType, (value) => value + 1,
          ifAbsent: () => 1);
    }
    final sortedMistakeTypes = mistakeTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        Text('Your progress',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'This week'),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _MetricPanel(
                label: 'Today',
                value: formatMinutes(controller.todayMinutes),
                icon: Icons.today_outlined),
            _MetricPanel(
                label: 'This week',
                value: formatMinutes(
                    controller.weeklyMinutes.fold(0, (a, b) => a + b)),
                icon: Icons.calendar_view_week_outlined),
            _MetricPanel(
                label: 'Best day',
                value: formatMinutes(controller.bestDayMinutes),
                icon: Icons.emoji_events_outlined),
            _MetricPanel(
                label: 'Streak',
                value: '${controller.currentStreak} days',
                icon: Icons.local_fire_department_outlined),
            _MetricPanel(
                label: 'Tasks done',
                value: '$doneTasks',
                icon: Icons.task_alt_outlined),
          ],
        ),
        const SizedBox(height: 17),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily focus minutes',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                WeeklyChart(values: controller.weeklyMinutes),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last 30 days',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _ActivityHeatmap(values: controller.last30DaysMinutes),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By subject',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                if (subjectData.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Complete a session to see subject statistics.',
                        style: TextStyle(color: Palette.muted)),
                  ),
                ...subjectData.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                          Text('${(entry.value / subjectTotal * 100).round()}%',
                              style: const TextStyle(color: Palette.muted))
                        ]),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                            value: entry.value / subjectTotal,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(6)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly subject goals',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                ...controller.subjects.map((subject) {
                  final minutes =
                      controller.weeklyMinutesForSubject(subject.id);
                  final progress =
                      (minutes / subject.weeklyGoalMinutes).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Text(subject.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700))),
                        Text('$minutes / ${subject.weeklyGoalMinutes} min',
                            style: const TextStyle(color: Palette.muted)),
                      ]),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                          value: progress,
                          color: Color(subject.colorValue),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(6)),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Task progress',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _StatRow(label: 'Active tasks', value: '$activeTasks'),
                _StatRow(label: 'Completed tasks', value: '$doneTasks'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mistake analysis',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                _StatRow(
                    label: 'Unresolved',
                    value: '${controller.unresolvedMistakeCount}'),
                if (sortedMistakeTypes.isEmpty)
                  const Text('No mistakes logged yet.',
                      style: TextStyle(color: Palette.muted))
                else
                  ...sortedMistakeTypes.take(3).map((entry) =>
                      _StatRow(label: entry.key, value: '${entry.value}')),
              ],
            ),
          ),
        ),
        if (controller.upcomingExams.isNotEmpty) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Exam readiness',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  ...controller.upcomingExams.take(4).map((exam) {
                    final related = controller.tasks
                        .where((task) => task.examId == exam.id)
                        .toList();
                    final completed = related
                        .where((task) => task.status == TaskStatus.done)
                        .length;
                    final readiness = related.isEmpty
                        ? 0
                        : (completed / related.length * 100).round();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                              child: Text(exam.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                          Text('$readiness%',
                              style: const TextStyle(color: Palette.muted)),
                        ]),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                            value: readiness / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(6)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18)),
              Text(label,
                  style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.values});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.fold(0, math.max));
    final primary = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(builder: (context, constraints) {
      const cols = 10;
      const rows = 3;
      const gap = 4.0;
      final cellSize = (constraints.maxWidth - gap * (cols - 1)) / cols;
      final today = DateTime.now();
      return SizedBox(
        height: rows * cellSize + (rows - 1) * gap + 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(values.length, (index) {
                final minutes = values[index];
                final intensity = minutes == 0 ? 0.0 : (minutes / maxValue);
                final day = today.subtract(Duration(days: 29 - index));
                final isToday = sameDay(day, today);
                return Tooltip(
                  message: '${_shortDate(day)}: ${formatMinutes(minutes)}',
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: minutes == 0
                          ? Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .3)
                          : primary.withValues(alpha: 0.2 + intensity * 0.7),
                      border: isToday
                          ? Border.all(color: primary, width: 1.5)
                          : null,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Less',
                  style: TextStyle(fontSize: 10, color: Palette.muted)),
              const SizedBox(width: 6),
              ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: primary.withValues(alpha: 0.2 + i * 0.23),
                      ),
                    ),
                  )),
              const SizedBox(width: 3),
              const Text('More',
                  style: TextStyle(fontSize: 10, color: Palette.muted)),
            ]),
          ],
        ),
      );
    });
  }
}

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({required this.values, super.key});
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, values.fold(0, math.max));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 154,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final height = 108 * values[index] / maxValue;
          final today = index == DateTime.now().weekday - 1;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(values[index] == 0 ? '' : '${values[index]}',
                    style: const TextStyle(fontSize: 10, color: Palette.muted)),
                const SizedBox(height: 4),
                AnimatedContainer(
                  height: math.max(height, 7),
                  width: 25,
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                      color: today
                          ? Theme.of(context).colorScheme.primary
                          : Palette.mint.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(5)),
                ),
                const SizedBox(height: 7),
                Text(labels[index],
                    style: TextStyle(
                        fontWeight: today ? FontWeight.w900 : FontWeight.w500,
                        color: Palette.muted)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ItemCategory selected = ItemCategory.hats;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items =
        shopCatalog.where((item) => item.category == selected).toList();
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Shop', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _Pill(
                  icon: Icons.monetization_on_outlined,
                  value: '${widget.controller.coins}',
                  color: Palette.amber),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          _ShopPreviewCard(controller: widget.controller),
          const SizedBox(height: 22),
          _SectionHeader(title: 'Customize ${widget.controller.petName}'),
          const SizedBox(height: 12),
          Row(
            children: ItemCategory.values
                .map((category) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: _ShopCategoryButton(
                          category: category,
                          selected: selected == category,
                          onTap: () => setState(() => selected = category),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: Text(selected.label,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900))),
            Text('${items.length} items',
                style: const TextStyle(color: Palette.muted)),
          ]),
          const SizedBox(height: 12),
          ...items.map(
              (item) => _ShopCard(controller: widget.controller, item: item)),
        ],
      ),
    );
  }
}

class _ShopPreviewCard extends StatelessWidget {
  const _ShopPreviewCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: .18),
          Palette.mint.withValues(alpha: .12),
        ]),
      ),
      child: Row(children: [
        PetIllustration(
          kind: controller.petKind,
          state: PetState.happy,
          size: 84,
          hat: controller.equipped[ItemCategory.hats],
          effect: controller.equipped[ItemCategory.effects],
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${controller.petName}\'s collection',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 4),
            const Text('Spend focus coins on a study setup.',
                style: TextStyle(color: Palette.muted, fontSize: 12)),
            const SizedBox(height: 9),
            Text('${controller.purchasedItems.length} items owned',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

class _ShopCategoryButton extends StatelessWidget {
  const _ShopCategoryButton(
      {required this.category, required this.selected, required this.onTap});
  final ItemCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 70,
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: .14)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? primary
                  : Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_categoryIcon(category),
              color: selected ? primary : Palette.muted, size: 21),
          const SizedBox(height: 5),
          Text(category.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selected ? primary : Palette.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11)),
        ]),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.controller, required this.item});
  final AppController controller;
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final owned = controller.purchasedItems.contains(item.id);
    final equipped = controller.isEquipped(item);
    final accent = _categoryColor(item.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16)),
              child: _ShopItemPreview(item: item, petKind: controller.petKind),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.monetization_on_rounded,
                        color: Palette.amber, size: 16),
                    const SizedBox(width: 3),
                    Text('${item.price}',
                        style: const TextStyle(
                            color: Palette.muted, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
            if (equipped)
              SizedBox(
                width: 92,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Palette.mint,
                    side: const BorderSide(color: Palette.mint),
                  ),
                  onPressed: () => controller.unequip(item),
                  child: const Text('Unequip'),
                ),
              )
            else
              SizedBox(
                width: 92,
                child: owned
                    ? OutlinedButton(
                        onPressed: () => controller.equip(item),
                        child: const Text('Equip'))
                    : FilledButton.tonal(
                        onPressed: controller.coins >= item.price
                            ? () async {
                                final purchased =
                                    await controller.purchase(item);
                                if (purchased && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('${item.name} purchased.')));
                                }
                              }
                            : null,
                        child: const Text('Buy'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopItemPreview extends StatelessWidget {
  const _ShopItemPreview({required this.item, required this.petKind});
  final ShopItem item;
  final PetKind petKind;

  @override
  Widget build(BuildContext context) {
    if (item.category == ItemCategory.hats) {
      return PetIllustration(
          kind: petKind, state: PetState.happy, size: 57, hat: item.id);
    }
    if (item.category == ItemCategory.effects) {
      return PetIllustration(
          kind: petKind, state: PetState.happy, size: 57, effect: item.id);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _HabitatPainter(
          background:
              item.category == ItemCategory.backgrounds ? item.id : null,
          roomItem: item.category == ItemCategory.room ? item.id : null,
          compact: true,
        ),
      ),
    );
  }
}

IconData _categoryIcon(ItemCategory category) => switch (category) {
      ItemCategory.hats => Icons.school_outlined,
      ItemCategory.room => Icons.chair_outlined,
      ItemCategory.backgrounds => Icons.wallpaper_outlined,
      ItemCategory.effects => Icons.auto_awesome_outlined,
    };

Color _categoryColor(ItemCategory category) => switch (category) {
      ItemCategory.hats => Palette.amber,
      ItemCategory.room => Palette.mint,
      ItemCategory.backgrounds => Palette.primary,
      ItemCategory.effects => Palette.coral,
    };

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final reminder = TimeOfDay(
        hour: controller.reminderHour, minute: controller.reminderMinute);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
        children: [
          const _SettingsHeader('Profile'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Your name'),
            trailing: Text(controller.userName,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            onTap: () => _editUserName(context),
          ),
          const _SettingsHeader('Goals'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Daily focus goal'),
            subtitle: const Text('How many minutes to focus each day'),
            trailing: Text('${controller.dailyGoalMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            onTap: () => _editDailyGoal(context),
          ),
          const _SettingsHeader('Preferences'),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Session completion and daily reminder'),
            value: controller.notificationsEnabled,
            onChanged: (value) async {
              final enabled = await controller.setNotifications(value);
              if (value && !enabled && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Notifications permission was not allowed.')));
              }
            },
          ),
          ListTile(
            enabled: controller.notificationsEnabled,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Daily reminder time'),
            trailing: Text(reminder.format(context),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            onTap: !controller.notificationsEnabled
                ? null
                : () async {
                    final chosen = await showTimePicker(
                        context: context, initialTime: reminder);
                    if (chosen != null) {
                      await controller.setReminderTime(
                          chosen.hour, chosen.minute);
                    }
                  },
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback preference'),
            value: controller.vibrationEnabled,
            onChanged: controller.setVibration,
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: controller.darkMode,
            onChanged: controller.setDarkMode,
          ),
          const SizedBox(height: 16),
          const _SettingsHeader('Data'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            subtitle: const Text('Progress is kept locally on this device.'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'FocusPet',
              applicationVersion: '0.1.0',
              children: const [
                Text(
                    'FocusPet stores your focus history and preferences locally. No account or cloud service is used.')
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            title: Text('Reset progress',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700)),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  Future<void> _editDailyGoal(BuildContext context) async {
    var minutes = controller.dailyGoalMinutes;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Daily focus goal'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Aim for this many focus minutes every day.',
                style: TextStyle(color: Palette.muted)),
            const SizedBox(height: 16),
            Row(children: [
              IconButton(
                  onPressed: () =>
                      setLocal(() => minutes = math.max(15, minutes - 15)),
                  icon: const Icon(Icons.remove_circle_outline)),
              Expanded(
                  child: Text('$minutes min',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900))),
              IconButton(
                  onPressed: () =>
                      setLocal(() => minutes = math.min(480, minutes + 15)),
                  icon: const Icon(Icons.add_circle_outline)),
            ]),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, minutes),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (result != null) await controller.setDailyGoal(result);
  }

  Future<void> _editUserName(BuildContext context) async {
    final input = TextEditingController(text: controller.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Alex'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, input.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    input.dispose();
    if (name != null && name.isNotEmpty) {
      await controller.updateUserName(name);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
            'This deletes sessions, tasks, exams, mistakes, XP, coins, streaks, and purchased items. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep progress')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (reset == true) {
      await controller.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress has been reset.')));
      }
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                color: Palette.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(
              child: Text(label, style: const TextStyle(color: Palette.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
        ]),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 17))),
          if (trailing != null)
            Text(trailing!,
                style: const TextStyle(
                    color: Palette.mint,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
        ],
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900))
        ]),
      );
}

enum PetState { happy, focused, sleepy, proud }

class PetIllustration extends StatefulWidget {
  const PetIllustration(
      {required this.kind,
      required this.state,
      required this.size,
      this.hat,
      this.effect,
      super.key});
  final PetKind kind;
  final PetState state;
  final double size;
  final String? hat;
  final String? effect;

  @override
  State<PetIllustration> createState() => _PetIllustrationState();
}

class _PetIllustrationState extends State<PetIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * math.sin(animation.value * math.pi)),
        child: child,
      ),
      child: CustomPaint(
          size: Size.square(widget.size),
          painter: PetPainter(
              kind: widget.kind,
              petState: widget.state,
              hat: widget.hat,
              effect: widget.effect)),
    );
  }
}

class PetPainter extends CustomPainter {
  PetPainter(
      {required this.kind, required this.petState, this.hat, this.effect});
  final PetKind kind;
  final PetState petState;
  final String? hat;
  final String? effect;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120;
    final paint = Paint()..isAntiAlias = true;
    final outline = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink;
    final center = Offset(size.width / 2, size.height / 2);

    _drawEffect(canvas, size, paint);
    paint.color = const Color(0xFFDCE7E5);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx, size.height * .87),
            width: size.width * .68,
            height: size.height * .09),
        paint);

    switch (kind) {
      case PetKind.robot:
        _robot(canvas, size, paint, outline);
      case PetKind.bunny:
        _bunny(canvas, size, paint, outline);
      case PetKind.cat:
        _cat(canvas, size, paint, outline);
    }
    _drawHat(canvas, size, paint, outline);
  }

  void _robot(Canvas canvas, Size size, Paint paint, Paint outline) {
    final s = size.width / 120;
    paint.color = const Color(0xFF60D2B4);
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(29 * s, 56 * s, 62 * s, 44 * s), Radius.circular(17 * s));
    canvas.drawRRect(body, paint);
    canvas.drawRRect(body, outline);
    paint.color = const Color(0xFF597BE5);
    final head = RRect.fromRectAndRadius(
        Rect.fromLTWH(24 * s, 22 * s, 72 * s, 53 * s), Radius.circular(18 * s));
    canvas.drawRRect(head, paint);
    canvas.drawRRect(head, outline);
    paint.color = Palette.amber;
    canvas.drawCircle(Offset(60 * s, 13 * s), 5 * s, paint);
    canvas.drawLine(Offset(60 * s, 18 * s), Offset(60 * s, 22 * s), outline);
    _face(canvas, size, paint, 45, 75, 46);
  }

  void _bunny(Canvas canvas, Size size, Paint paint, Paint outline) {
    final s = size.width / 120;
    paint.color = const Color(0xFFFAF5F0);
    for (final x in [42.0, 68.0]) {
      final ear = RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, 4 * s, 17 * s, 45 * s), Radius.circular(13 * s));
      canvas.drawRRect(ear, paint);
      canvas.drawRRect(ear, outline);
    }
    final head =
        Rect.fromCircle(center: Offset(60 * s, 61 * s), radius: 36 * s);
    canvas.drawOval(head, paint);
    canvas.drawOval(head, outline);
    paint.color = const Color(0xFFFFB5AE);
    canvas.drawCircle(Offset(60 * s, 67 * s), 4 * s, paint);
    _face(canvas, size, paint, 47, 73, 58);
  }

  void _cat(Canvas canvas, Size size, Paint paint, Paint outline) {
    final s = size.width / 120;
    paint.color = const Color(0xFFFFCE71);
    final path = Path()
      ..moveTo(28 * s, 48 * s)
      ..lineTo(29 * s, 14 * s)
      ..lineTo(50 * s, 28 * s)
      ..quadraticBezierTo(60 * s, 23 * s, 70 * s, 28 * s)
      ..lineTo(91 * s, 14 * s)
      ..lineTo(92 * s, 48 * s)
      ..quadraticBezierTo(96 * s, 84 * s, 60 * s, 94 * s)
      ..quadraticBezierTo(24 * s, 84 * s, 28 * s, 48 * s)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outline);
    _face(canvas, size, paint, 46, 74, 53);
  }

  void _face(Canvas canvas, Size size, Paint paint, double leftX, double rightX,
      double y) {
    final s = size.width / 120;
    if (petState == PetState.sleepy) {
      final faceOutline = Paint()
        ..color = Palette.ink
        ..strokeWidth = 2.5 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset((leftX - 4) * s, y * s),
          Offset((leftX + 4) * s, y * s), faceOutline);
      canvas.drawLine(Offset((rightX - 4) * s, y * s),
          Offset((rightX + 4) * s, y * s), faceOutline);
    } else {
      final eyes = Paint()
        ..isAntiAlias = true
        ..color = Palette.ink;
      final highlight = Paint()
        ..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: .85);
      for (final x in [leftX, rightX]) {
        canvas.drawCircle(Offset(x * s, y * s), 4.6 * s, eyes);
        canvas.drawCircle(
            Offset((x - 1.2) * s, (y - 1.4) * s), 1.35 * s, highlight);
      }
    }
    final mouth = Paint()
      ..color = Palette.ink
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(60 * s, (y + 9) * s), width: 17 * s, height: 10 * s),
        .18,
        math.pi - .36,
        false,
        mouth);
  }

  void _drawHat(Canvas canvas, Size size, Paint paint, Paint outline) {
    if (hat == null) return;
    final s = size.width / 120;
    final top = switch (kind) {
      PetKind.bunny => 28.0,
      PetKind.cat => 17.0,
      PetKind.robot => 13.0,
    };
    if (hat == 'blue_cap') {
      final capOutline = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..color = const Color(0xFF253A82);
      final crown = Path()
        ..moveTo(37 * s, (top + 12) * s)
        ..quadraticBezierTo(39 * s, top * s, 58 * s, (top - 2) * s)
        ..quadraticBezierTo(77 * s, top * s, 79 * s, (top + 12) * s)
        ..close();
      paint.color = const Color(0xFF5276EA);
      canvas.drawPath(crown, paint);
      canvas.drawPath(crown, capOutline);
      paint.color = const Color(0xFF7192F4);
      canvas.drawPath(
          Path()
            ..moveTo(44 * s, (top + 7) * s)
            ..quadraticBezierTo(47 * s, (top + 1) * s, 61 * s, top * s),
          Paint()
            ..isAntiAlias = true
            ..color = const Color(0xFF9BB3FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * s);
      final brim = RRect.fromRectAndRadius(
          Rect.fromLTWH(30 * s, (top + 11) * s, 59 * s, 6 * s),
          Radius.circular(3 * s));
      paint.color = const Color(0xFF3558C7);
      canvas.drawRRect(brim, paint);
      canvas.drawRRect(brim, capOutline);
    } else if (hat == 'grad_cap') {
      final capY = top + 5;
      paint.color = const Color(0xFF202D4A);
      final cap = Path()
        ..moveTo(29 * s, capY * s)
        ..lineTo(60 * s, (capY - 13) * s)
        ..lineTo(91 * s, capY * s)
        ..lineTo(60 * s, (capY + 13) * s)
        ..close();
      canvas.drawPath(cap, paint);
      paint.color = const Color(0xFF394B70);
      canvas.drawPath(
          Path()
            ..moveTo(42 * s, (capY + 6) * s)
            ..quadraticBezierTo(60 * s, (capY + 15) * s, 78 * s, (capY + 6) * s)
            ..lineTo(77 * s, (capY + 14) * s)
            ..quadraticBezierTo(
                60 * s, (capY + 22) * s, 43 * s, (capY + 14) * s)
            ..close(),
          paint);
      final tassel = Paint()
        ..color = Palette.amber
        ..strokeWidth = 1.8 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(82 * s, capY * s), Offset(84 * s, (capY + 24) * s), tassel);
      canvas.drawCircle(Offset(84 * s, (capY + 26) * s), 2.8 * s, tassel);
    } else if (hat == 'headphones') {
      final centerY = kind == PetKind.bunny ? 48.0 : 40.0;
      final headset = Paint()
        ..color = const Color(0xFF314775)
        ..strokeWidth = 5.5 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(60 * s, centerY * s),
              width: 76 * s,
              height: 69 * s),
          math.pi,
          math.pi,
          false,
          headset);
      for (final x in [24.0, 86.0]) {
        final cup = RRect.fromRectAndRadius(
            Rect.fromLTWH(x * s, (centerY + 4) * s, 12 * s, 23 * s),
            Radius.circular(6 * s));
        paint.color = const Color(0xFF5276EA);
        canvas.drawRRect(cup, paint);
        canvas.drawRRect(cup, headset);
      }
    }
  }

  void _drawEffect(Canvas canvas, Size size, Paint paint) {
    final s = size.width / 120;
    if (effect == 'rain') {
      final rain = Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFF70B9E9).withValues(alpha: .8)
        ..strokeWidth = 2 * s
        ..strokeCap = StrokeCap.round;
      for (final drop in const [
        [17.0, 34.0],
        [101.0, 29.0],
        [12.0, 63.0],
        [104.0, 68.0],
        [92.0, 92.0],
      ]) {
        canvas.drawLine(Offset(drop[0] * s, drop[1] * s),
            Offset((drop[0] - 4) * s, (drop[1] + 9) * s), rain);
      }
      return;
    }
    if (effect != 'sparkle') return;
    paint.color = Palette.amber;
    for (final spark in const [
      [18.0, 31.0, 5.0],
      [101.0, 39.0, 4.5],
      [21.0, 78.0, 3.7],
      [98.0, 83.0, 5.2],
    ]) {
      final x = spark[0] * s;
      final y = spark[1] * s;
      final radius = spark[2] * s;
      final path = Path()
        ..moveTo(x, y - radius)
        ..lineTo(x + radius * .35, y - radius * .35)
        ..lineTo(x + radius, y)
        ..lineTo(x + radius * .35, y + radius * .35)
        ..lineTo(x, y + radius)
        ..lineTo(x - radius * .35, y + radius * .35)
        ..lineTo(x - radius, y)
        ..lineTo(x - radius * .35, y - radius * .35)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PetPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.petState != petState ||
      oldDelegate.hat != hat ||
      oldDelegate.effect != effect;
}
