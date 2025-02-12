import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_shared_tools/constant/constant.dart';
import 'package:flutter_shared_tools/extensions/extensions.dart';

import '../setup.dart';
import '../stores/localization_store.dart';
import '../stores/settings_store.dart';
import '../stores/theme_store.dart';
import '../utils/app_icons.dart';
import '../utils/app_localization_strings.dart';
import '../utils/context_confirm.dart';
import '../utils/copy_to_clipboard.dart';
import '../utils/open_url.dart';
import '../utils/stringify_uri_location.dart';
import '../widgets/animated_app_name.dart';
import '../widgets/app_icon_button.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/horizontal_rule.dart';
import '../widgets/sliver_app_bar_translucent.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with
        SettingsStoreMixin,
        ThemeStoreMixin<SettingsPage>,
        LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          AnimatedBuilder(
            animation: settingsStore,
            builder: (BuildContext context, Widget? child) {
              return SliverAppBarTranslucent(
                pinned: !settingsStore.getBoolPreference(
                  SettingsBoolPreference.hideAppBarOnScroll,
                ),
                titleSpacing: 0,
                leading: !Navigator.canPop(context)
                    ? null
                    : IconButton(
                        icon: Icon(
                          AppIcons.arrowLeft.data,
                          size: kDefaultIconSize,
                          color: context.isDark ? null : context.primaryColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                title: Text(
                  context.strings.settings,
                  style: context.theme.appBarTheme.titleTextStyle!.copyWith(
                    color: context.theme.textTheme.labelSmall!.color,
                  ),
                ),
                actions: <Widget>[
                  AppIconButton(
                    icon: Icon(
                      AppIcons.reset.data,
                      size: kDefaultIconSize,
                      color: context.isDark ? null : context.primaryColor,
                    ),
                    tooltip: context.strings.resetAllPreferences,
                    onTap: () async {
                      final bool confirmed = await showConfirmationModal(
                        context: context,
                        message: context.strings.resetAllPreferencesQuestion,
                      );

                      if (confirmed) {
                        await settingsStore.reset();
                        await themeStore.reset();
                        await localizationStore.reset();
                      }
                    },
                  ),
                ],
              );
            },
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              <Widget>[
                SettingsTileTitle(context.strings.export),
                const ExportLocationSettingsTile(),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.display),
                const AppThemeSettingsTile(),
                const AppFontFamilySettingsTile(),
                const AppLocalizationSettingsTile(),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.behaviorPreferences),
                AppBooleanPreferencesSettingsTile(
                  values: SettingsBoolPreference.filterBy(
                    category: SettingsBoolPreferenceCategory.behavior,
                  ),
                ),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.appearancePreferences),
                const AppOverscrollPhysicsTile(),
                AppBooleanPreferencesSettingsTile(
                  values: SettingsBoolPreference.filterBy(
                    category: SettingsBoolPreferenceCategory.appearance,
                  ),
                ),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.donate),
                const DonationSettingsTile(),
                const HorizontalRule(),
                SettingsTileTitle(context.strings.links),
                const RelatedLinks(),
                const HorizontalRule(),
                const Padding(
                  padding: EdgeInsets.all(k20dp),
                  child: Center(child: AnimatedAppName()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTileTitle extends StatelessWidget {
  const SettingsTileTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: k10dp,
        vertical: k6dp,
      ).copyWith(top: k12dp),
      child: Text(
        title,
        style: TextStyle(
          color: context.theme.disabledColor,
        ),
      ),
    );
  }
}

class RelatedLinks extends StatefulWidget {
  const RelatedLinks({super.key});

  @override
  State<RelatedLinks> createState() => _RelatedLinksState();
}

class _RelatedLinksState extends State<RelatedLinks>
    with BasicTileBuilderMixin<RelatedLinks> {
  final String _packageVersion =
      '${packageInfo.packageName} v${packageInfo.version}+${packageInfo.buildNumber}';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildTile(
          title: context.strings.openSourceLicenses,
          onTap: () => showLicensePage(context: context),
        ),
        buildTile(
          title: context.strings.reportIssue,
          onTap: openThisLink('https://github.com/alexrintt/kanade/issues'),
        ),
        buildTile(
          title: context.strings.followMeOnGitHub,
          onTap: openThisLink('https://github.com/alexrintt'),
          description: '@alexrintt',
        ),
        buildTile(
          title: context.strings.githubRepository,
          onTap: openThisLink('https://github.com/alexrintt/kanade'),
          description: 'github.com/alexrintt/kanade',
        ),
        buildTile(
          title: context.strings.packageAndVersion,
          onTap: copyThisText(_packageVersion),
          description: _packageVersion,
        ),
      ],
    );
  }
}

class ExportLocationSettingsTile extends StatefulWidget {
  const ExportLocationSettingsTile({super.key});

  @override
  State<ExportLocationSettingsTile> createState() =>
      _ExportLocationSettingsTileState();
}

class _ExportLocationSettingsTileState extends State<ExportLocationSettingsTile>
    with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: settingsStore.requestExportLocation,
      child: AnimatedBuilder(
        animation: settingsStore,
        builder: (BuildContext context, Widget? child) {
          final String? exportLocation = stringifyTreeUri(
            settingsStore.exportLocation,
          );

          return AppListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: k10dp,
            ),
            enableFeedback: true,
            leading: Icon(AppIcons.folder.data, size: AppIcons.folder.size),
            title: Text(context.strings.selectOutputFolder),
            subtitle: Text(exportLocation ?? context.strings.notDefined),
            trailing: Icon(
              AppIcons.chevronRight.data,
              size: AppIcons.chevronRight.size,
            ),
          );
        },
      ),
    );
  }
}

class AppThemeSettingsTile extends StatefulWidget {
  const AppThemeSettingsTile({super.key});

  @override
  State<AppThemeSettingsTile> createState() => _AppThemeSettingsTileState();
}

class _AppThemeSettingsTileState extends State<AppThemeSettingsTile>
    with ThemeStoreMixin<AppThemeSettingsTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) => const ChangeThemeDialog(),
        );
      },
      child: AppListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: Icon(AppIcons.styling.data, size: AppIcons.styling.size),
        title: Text(context.strings.theme),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (BuildContext context, Widget? child) {
            return Text(
              themeStore.currentTheme.getNameString(context.strings),
            );
          },
        ),
      ),
    );
  }
}

class ChangeThemeDialog extends StatefulWidget {
  const ChangeThemeDialog({super.key});

  @override
  State<ChangeThemeDialog> createState() => _ChangeThemeDialogState();
}

class _ChangeThemeDialogState extends State<ChangeThemeDialog>
    with ThemeStoreMixin<ChangeThemeDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          title: Text(context.strings.theme),
          children: <Widget>[
            for (final AppTheme theme in AppTheme.values)
              RadioListTile<AppTheme>(
                groupValue: themeStore.currentTheme,
                value: theme,
                title: Text(theme.getNameString(context.strings)),
                onChanged: (AppTheme? value) => themeStore.setTheme(value!),
              ),
          ],
        );
      },
    );
  }
}

class AppOverscrollPhysicsTile extends StatefulWidget {
  const AppOverscrollPhysicsTile({super.key});

  @override
  State<AppOverscrollPhysicsTile> createState() =>
      _AppOverscrollPhysicsTileState();
}

class _AppOverscrollPhysicsTileState extends State<AppOverscrollPhysicsTile>
    with ThemeStoreMixin<AppOverscrollPhysicsTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              const ChangeOverscrollPhysicsDialog(),
        );
      },
      child: AppListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        title: Text(context.strings.overscrollIndicator),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (BuildContext context, Widget? child) {
            return Text(
              themeStore.currentOverscrollPhysics
                  .getNameString(context.strings),
            );
          },
        ),
      ),
    );
  }
}

class ChangeOverscrollPhysicsDialog extends StatefulWidget {
  const ChangeOverscrollPhysicsDialog({super.key});

  @override
  State<ChangeOverscrollPhysicsDialog> createState() =>
      _ChangeOverscrollPhysicsDialogState();
}

class _ChangeOverscrollPhysicsDialogState
    extends State<ChangeOverscrollPhysicsDialog>
    with ThemeStoreMixin<ChangeOverscrollPhysicsDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          title: Text(context.strings.theme),
          children: <Widget>[
            for (final OverscrollPhysics overscrollPhysics
                in OverscrollPhysics.values)
              RadioListTile<OverscrollPhysics>(
                groupValue: themeStore.currentOverscrollPhysics,
                value: overscrollPhysics,
                title: Text(overscrollPhysics.getNameString(context.strings)),
                onChanged: (OverscrollPhysics? value) =>
                    themeStore.setOverscrollPhysics(value!),
              ),
          ],
        );
      },
    );
  }
}

class AppFontFamilySettingsTile extends StatefulWidget {
  const AppFontFamilySettingsTile({super.key});

  @override
  State<AppFontFamilySettingsTile> createState() =>
      _AppFontFamilySettingsTileState();
}

class _AppFontFamilySettingsTileState extends State<AppFontFamilySettingsTile>
    with ThemeStoreMixin<AppFontFamilySettingsTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              const ChangeThemeFontFamilyDialog(),
        );
      },
      child: AppListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: Icon(AppIcons.fontFamily.data, size: AppIcons.fontFamily.size),
        title: Text(context.strings.fontFamily),
        subtitle: AnimatedBuilder(
          animation: themeStore,
          builder: (BuildContext context, Widget? child) {
            return Text(
              themeStore.currentFontFamily.fontKey,
            );
          },
        ),
      ),
    );
  }
}

class ChangeThemeFontFamilyDialog extends StatefulWidget {
  const ChangeThemeFontFamilyDialog({super.key});

  @override
  State<ChangeThemeFontFamilyDialog> createState() =>
      _ChangeThemeFontFamilyDialogState();
}

class _ChangeThemeFontFamilyDialogState
    extends State<ChangeThemeFontFamilyDialog>
    with ThemeStoreMixin<ChangeThemeFontFamilyDialog> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          // shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.fontFamily),
          children: <Widget>[
            for (final AppFontFamily fontFamily in AppFontFamily.values
                .where((AppFontFamily e) => e.displayable))
              RadioListTile<AppFontFamily>(
                groupValue: themeStore.currentFontFamily,
                value: fontFamily,
                title: Text(fontFamily.fontKey),
                onChanged: (AppFontFamily? value) =>
                    themeStore.setFontFamily(value!),
              ),
          ],
        );
      },
    );
  }
}

mixin BasicTileBuilderMixin<T extends StatefulWidget> on State<T> {
  Widget buildTile({
    required String title,
    String? description,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AppListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        title: Text(title),
        subtitle: description != null ? Text(description) : null,
      ),
    );
  }

  VoidCallback openThisLink(String url) {
    return () => openUri(Uri.parse(url));
  }

  VoidCallback copyThisText(String text) {
    return () async {
      await context.copyTextToClipboardAndShowToast(text);
    };
  }
}

class DonationSettingsTile extends StatefulWidget {
  const DonationSettingsTile({super.key});

  @override
  State<DonationSettingsTile> createState() => _DonationSettingsTileState();
}

class _DonationSettingsTileState extends State<DonationSettingsTile>
    with BasicTileBuilderMixin<DonationSettingsTile> {
  final String _btcAddress = 'bc1qacmk9z48m7upaaq2jl80u6dxsyld443jdjufv9';
  final Uri _livePix = Uri.parse('https://livepix.gg/alexrintt');
  final Uri _githubSponsor = Uri.parse('https://github.com/sponsors/alexrintt');
  final Uri _kofi = Uri.parse('https://ko-fi.com/alexrintt');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildTile(
          title: context.strings.donateOnGitHub,
          onTap: openThisLink(_githubSponsor.toString()),
          description: _githubSponsor.host + _githubSponsor.path,
        ),
        buildTile(
          title: context.strings.donateOnKofi,
          onTap: openThisLink(_kofi.toString()),
          description: _kofi.host + _kofi.path,
        ),
        buildTile(
          title: context.strings.donateUsingPix,
          onTap: openThisLink(_livePix.toString()),
          description: _livePix.host + _livePix.path,
        ),
        buildTile(
          title: context.strings.donateUsingBtc,
          onLongPress: copyThisText(_btcAddress),
          onTap: copyThisText(_btcAddress),
          description: _btcAddress,
        ),
        buildTile(
          title: context.strings.otherDonationMethods,
          onTap: openThisLink('https://donate.alexrintt.io'),
          description: 'donate.alexrintt.io',
        ),
      ],
    );
  }
}

class AppBooleanPreferencesSettingsTile extends StatefulWidget {
  const AppBooleanPreferencesSettingsTile({super.key, required this.values});

  final List<SettingsBoolPreference> values;

  @override
  State<AppBooleanPreferencesSettingsTile> createState() =>
      _AppBooleanPreferencesSettingsTileState();
}

class _AppBooleanPreferencesSettingsTileState
    extends State<AppBooleanPreferencesSettingsTile> with SettingsStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsStore,
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final SettingsBoolPreference preference in widget.values)
              InkWell(
                onTap: () => settingsStore.toggleBoolPreference(preference),
                child: AppListTile(
                  tileColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: k10dp,
                  ),
                  enableFeedback: true,
                  isThreeLine: true,
                  trailing: Switch(
                    trackColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return context.primaryColor;
                        }
                        return context.scaffoldBackgroundColor;
                      },
                    ),
                    overlayColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        return context.theme.highlightColor;
                      },
                    ),
                    thumbColor: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          if (context.isDark) {
                            return context.theme.disabledColor;
                          }
                          return context.theme.dividerColor;
                        }

                        return context.isDark
                            ? context.theme.disabledColor
                            : context.theme.disabledColor.withOpacity(.2);
                      },
                    ),
                    splashRadius: k12dp,
                    thumbIcon: MaterialStateProperty.resolveWith(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Icon(Icons.check, color: context.primaryColor);
                        }
                        return null;
                      },
                    ),
                    activeColor: context.primaryColor,
                    value: settingsStore.getBoolPreference(preference),
                    onChanged: (bool value) => settingsStore
                        .setBoolPreference(preference, value: value),
                  ),
                  title: Text(preference.getNameString(context.strings)),
                  subtitle: Text(
                    preference.getDescriptionString(context.strings),
                    style: context.textTheme.labelLarge!.copyWith(
                      color: context.isDark
                          ? context.theme.disabledColor
                          : context.theme.disabledColor.withOpacity(.35),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AppLocalizationSettingsTile extends StatefulWidget {
  const AppLocalizationSettingsTile({super.key});

  @override
  State<AppLocalizationSettingsTile> createState() =>
      _AppLocalizationSettingsTileState();
}

class _AppLocalizationSettingsTileState
    extends State<AppLocalizationSettingsTile> with LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              const ChangeAppLocalizationDialog(),
        );
      },
      child: AppListTile(
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: k10dp,
        ),
        enableFeedback: true,
        leading: Icon(AppIcons.language.data, size: AppIcons.language.size),
        title: Text(context.strings.language),
        subtitle: AnimatedBuilder(
          animation: localizationStore,
          builder: (BuildContext context, Widget? child) {
            if (localizationStore.fixedLocale == null) {
              String systemLanguageNotSupportedWarn = '';

              if (!localizationStore.isSystemLocalizationSupported) {
                systemLanguageNotSupportedWarn =
                    ', ${localizationStore.deviceLocale.fullName} ${context.strings.isNotSupportedYet}';
              }

              return Text(
                '${context.strings.followTheSystem} (${localizationStore.locale.fullName}$systemLanguageNotSupportedWarn)',
              );
            }
            return Text(localizationStore.fixedLocale!.fullName);
          },
        ),
      ),
    );
  }
}

class ChangeAppLocalizationDialog extends StatefulWidget {
  const ChangeAppLocalizationDialog({super.key});

  @override
  State<ChangeAppLocalizationDialog> createState() =>
      _ChangeAppLocalizationDialogState();
}

class _ChangeAppLocalizationDialogState
    extends State<ChangeAppLocalizationDialog> with LocalizationStoreMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localizationStore,
      builder: (BuildContext context, Widget? child) {
        return SimpleDialog(
          // shape: const MaterialYouDialogShape(),
          backgroundColor: context.theme.colorScheme.background,
          title: Text(context.strings.language),
          children: <Widget>[
            for (final Locale localization in AppLocalizations.supportedLocales)
              RadioListTile<Locale?>(
                groupValue: localizationStore.fixedLocale,
                value: localization,
                title: Text(localization.fullName),
                onChanged: (Locale? value) =>
                    localizationStore.setLocale(value),
              ),
            RadioListTile<Locale?>(
              groupValue: localizationStore.fixedLocale,
              value: null,
              title: Text(context.strings.followTheSystem),
              onChanged: (Locale? value) => localizationStore.setLocale(value),
            ),
          ],
        );
      },
    );
  }
}
