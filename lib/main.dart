import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ContactsImporterApp());
}

class ContactsImporterApp extends StatelessWidget {
  const ContactsImporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF006A6A),
    );
    return MaterialApp(
      title: 'Contacts Importer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(_index == 0 ? 'Uvoznik kontaktov' : 'O aplikaciji'),
      ),
      body: IndexedStack(
        index: _index,
        children: const [ImportView(), AboutView()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.cloud_download_outlined),
            selectedIcon: Icon(Icons.cloud_download),
            label: 'Uvoz',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'O aplikaciji',
          ),
        ],
      ),
    );
  }
}

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final TextEditingController _urlController = TextEditingController();
  final ContactsImporter _importer = ContactsImporter();

  bool _isLoading = false;
  String? _errorMessage;
  ImportSummary? _summary;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _startImport() async {
    FocusScope.of(context).unfocus();
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Vnesite URL do CSV datoteke.';
        _summary = null;
      });
      return;
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      setState(() {
        _errorMessage = 'Neveljaven URL. Preverite vnos in poskusite znova.';
        _summary = null;
      });
      return;
    }

    final isValidUri =
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isValidUri) {
      setState(() {
        _errorMessage = 'Neveljaven URL. Preverite vnos in poskusite znova.';
        _summary = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summary = null;
    });

    try {
      final summary = await _importer.importFromUrl(uri);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
      });
    } on ImportException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Pri uvozu je prišlo do nepričakovane napake. Poskusite znova.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Uvozi kontakte',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prilepite povezavo do Outlook CSV datoteke. Aplikacija bo '
                    'prenese podatke ter kontakte dodala ali posodobila na '
                    'napravi.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'URL do CSV datoteke',
                      hintText: 'https://primer.si/kontakti.csv',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    onSubmitted: (_) => _startImport(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _startImport,
                    icon: const Icon(Icons.sync),
                    label: const Text('Posodobi'),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading) const LinearProgressIndicator(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _StatusBanner(
                      message: _errorMessage!,
                      type: StatusType.error,
                    ),
                  ],
                  if (_summary != null) ...[
                    const SizedBox(height: 16),
                    _StatusBanner(
                      message: _summary!.completionMessage,
                      details: _summary!.detailsDescription,
                      type: StatusType.success,
                    ),
                    const SizedBox(height: 8),
                    _SummaryChips(summary: _summary!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'O aplikaciji',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Pellentesque habitant morbi tristique senectus et netus et '
                    'malesuada fames ac turpis egestas. Integer feugiat, tortor '
                    'vitae dapibus viverra, velit turpis fermentum nisl, eu '
                    'volutpat lectus erat sed justo.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusType { success, error }

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.type,
    this.details,
  });

  final String message;
  final StatusType type;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color tone = type == StatusType.success
        ? colorScheme.primary
        : colorScheme.error;
    final Color background = tone.withValues(alpha: 0.1);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              type == StatusType.success
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: tone,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      details!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: tone),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.summary});

  final ImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _SummaryStat(
        label: 'Skupaj',
        value: summary.total,
        icon: Icons.people_alt_outlined,
      ),
      _SummaryStat(
        label: 'Dodanih',
        value: summary.inserted,
        icon: Icons.person_add_alt_1_outlined,
      ),
      _SummaryStat(
        label: 'Posodobljenih',
        value: summary.updated,
        icon: Icons.auto_fix_high_outlined,
      ),
      _SummaryStat(
        label: 'Preskočenih',
        value: summary.skipped,
        icon: Icons.block_outlined,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final stat in stats)
          Chip(
            avatar: Icon(stat.icon, size: 18),
            label: Text('${stat.label}: ${stat.value}'),
          ),
      ],
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class ContactsImporter {
  ContactsImporter({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<ImportSummary> importFromUrl(Uri uri) async {
    final granted = await FlutterContacts.requestPermission();
    if (!granted) {
      throw const ImportException(
        'Za uvoz je potrebno dovoljenje za dostop do kontaktov.',
      );
    }

    final client = _client ?? http.Client();
    try {
      final response = await client.get(uri);
      if (response.statusCode >= 400) {
        throw ImportException(
          'CSV datoteke ni bilo mogoče prenesti (HTTP ${response.statusCode}).',
        );
      }

      final csvContent = _decodeResponse(response.bodyBytes);
      return importFromCsv(csvContent);
    } on PlatformException catch (error) {
      throw ImportException(
        'Dostop do kontaktov ni na voljo: ${error.message ?? 'neznana napaka'}.',
      );
    } on ImportException {
      rethrow;
    } catch (_) {
      throw const ImportException('Prenos CSV datoteke ni uspel.');
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<ImportSummary> importFromCsv(String csvContent) async {
    final parser = OutlookCsvParser();
    final records = parser.parse(csvContent);
    if (records.isEmpty) {
      return const ImportSummary(total: 0, inserted: 0, updated: 0, skipped: 0);
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withAccounts: true,
      withPhoto: true,
      sorted: false,
    );
    final matcher = _ContactMatcher(contacts);

    var inserted = 0;
    var updated = 0;
    var skipped = 0;

    for (final record in records) {
      if (!record.hasContent) {
        skipped++;
        continue;
      }

      final existing = matcher.findMatch(record);
      if (existing != null) {
        final merged = _mergeContact(existing, record);
        final persisted = await FlutterContacts.updateContact(merged);
        matcher.register(persisted);
        updated++;
      } else {
        final newContact = _createContact(record);
        if (newContact == null) {
          skipped++;
          continue;
        }
        final persisted = await FlutterContacts.insertContact(newContact);
        matcher.register(persisted);
        inserted++;
      }
    }

    return ImportSummary(
      total: records.length,
      inserted: inserted,
      updated: updated,
      skipped: skipped,
    );
  }

  Contact _mergeContact(Contact existing, ParsedContactRecord record) {
    final displayName = record.computedDisplayName;
    if (displayName != null && displayName.isNotEmpty) {
      existing.displayName = displayName;
    }

    final name = existing.name;
    if (record.firstName != null && record.firstName!.isNotEmpty) {
      name.first = record.firstName!;
    }
    if (record.middleName != null && record.middleName!.isNotEmpty) {
      name.middle = record.middleName!;
    }
    if (record.lastName != null && record.lastName!.isNotEmpty) {
      name.last = record.lastName!;
    }
    if (record.prefix != null && record.prefix!.isNotEmpty) {
      name.prefix = record.prefix!;
    }
    if (record.suffix != null && record.suffix!.isNotEmpty) {
      name.suffix = record.suffix!;
    }
    if (record.nickname != null && record.nickname!.isNotEmpty) {
      name.nickname = record.nickname!;
    }

    if (record.phones.isNotEmpty) {
      existing.phones = record.phones
          .map(
            (entry) => Phone(
              entry.number,
              label: entry.label,
              customLabel: entry.customLabel ?? '',
            ),
          )
          .toList();
    }

    if (record.emails.isNotEmpty) {
      existing.emails = record.emails
          .map(
            (entry) => Email(
              entry.address,
              label: entry.label,
              customLabel: entry.customLabel ?? '',
            ),
          )
          .toList();
    }

    if (record.addresses.isNotEmpty) {
      existing.addresses = record.addresses
          .map((entry) => Address(entry.formatted, label: entry.label))
          .toList();
    }

    final hasCompanyUpdate =
        record.company != null && record.company!.isNotEmpty;
    final hasJobTitleUpdate =
        record.jobTitle != null && record.jobTitle!.isNotEmpty;
    if (hasCompanyUpdate || hasJobTitleUpdate) {
      final previousOrganization = existing.organizations.isNotEmpty
          ? existing.organizations.first
          : Organization();
      existing.organizations = [
        Organization(
          company: hasCompanyUpdate
              ? record.company!
              : previousOrganization.company,
          title: hasJobTitleUpdate
              ? record.jobTitle!
              : previousOrganization.title,
          department: previousOrganization.department,
          jobDescription: previousOrganization.jobDescription,
          symbol: previousOrganization.symbol,
          phoneticName: previousOrganization.phoneticName,
          officeLocation: previousOrganization.officeLocation,
        ),
      ];
    }

    if (record.notes != null && record.notes!.isNotEmpty) {
      existing.notes = [Note(record.notes!)];
    }

    return existing;
  }

  Contact? _createContact(ParsedContactRecord record) {
    final displayName = record.computedDisplayName;
    if (displayName == null || displayName.isEmpty) {
      return null;
    }
    final contact = Contact();
    contact.displayName = displayName;
    contact.name.first = record.firstName ?? '';
    contact.name.middle = record.middleName ?? '';
    contact.name.last = record.lastName ?? '';
    contact.name.prefix = record.prefix ?? '';
    contact.name.suffix = record.suffix ?? '';
    contact.name.nickname = record.nickname ?? '';

    if (record.phones.isNotEmpty) {
      contact.phones = record.phones
          .map(
            (entry) => Phone(
              entry.number,
              label: entry.label,
              customLabel: entry.customLabel ?? '',
            ),
          )
          .toList();
    }

    if (record.emails.isNotEmpty) {
      contact.emails = record.emails
          .map(
            (entry) => Email(
              entry.address,
              label: entry.label,
              customLabel: entry.customLabel ?? '',
            ),
          )
          .toList();
    }

    if (record.addresses.isNotEmpty) {
      contact.addresses = record.addresses
          .map((entry) => Address(entry.formatted, label: entry.label))
          .toList();
    }

    if (record.company != null || record.jobTitle != null) {
      contact.organizations = [
        Organization(
          company: record.company ?? '',
          title: record.jobTitle ?? '',
        ),
      ];
    }

    if (record.notes != null && record.notes!.isNotEmpty) {
      contact.notes = [Note(record.notes!)];
    }

    return contact;
  }

  String _decodeResponse(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }
}

class ImportSummary {
  const ImportSummary({
    required this.total,
    required this.inserted,
    required this.updated,
    required this.skipped,
  });

  final int total;
  final int inserted;
  final int updated;
  final int skipped;

  String get completionMessage {
    final buffer = StringBuffer('Prenos končan');
    if (total == 0) {
      buffer.write(' – datoteka ne vsebuje veljavnih kontaktov.');
      return buffer.toString();
    }
    final details = <String>[];
    if (inserted > 0) {
      details.add('dodanih $inserted');
    }
    if (updated > 0) {
      details.add('posodobljenih $updated');
    }
    if (skipped > 0) {
      details.add('preskočenih $skipped');
    }
    if (details.isEmpty) {
      buffer.write(' – ni bilo sprememb.');
    } else {
      buffer.write(' – ${details.join(', ')}.');
    }
    return buffer.toString();
  }

  String get detailsDescription =>
      'Skupaj zapisov: $total • Dodanih: $inserted • Posodobljenih: '
      '$updated • Preskočenih: $skipped';
}

class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OutlookCsvParser {
  const OutlookCsvParser();

  List<ParsedContactRecord> parse(String csv) {
    if (csv.trim().isEmpty) {
      return const [];
    }

    var sanitized = csv.replaceAll('\r\n', '\n');
    if (sanitized.startsWith('\ufeff')) {
      sanitized = sanitized.substring(1);
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(sanitized, eol: '\n');
    if (rows.isEmpty) {
      return const [];
    }

    final headerRow = rows.first
        .map((dynamic value) => value?.toString().trim() ?? '')
        .toList();
    final headerMap = _buildHeaderIndex(headerRow);

    final records = <ParsedContactRecord>[];
    for (final dynamic rawRow in rows.skip(1)) {
      if (rawRow is! List) {
        continue;
      }
      final row = rawRow.cast<dynamic>();
      final record = _parseRow(row, headerMap);
      if (record.hasContent) {
        records.add(record);
      }
    }
    return records;
  }

  Map<String, List<int>> _buildHeaderIndex(List<String> headerRow) {
    final index = <String, List<int>>{};
    for (var i = 0; i < headerRow.length; i++) {
      final normalized = _normalizeHeader(headerRow[i]);
      if (normalized.isEmpty) {
        continue;
      }
      index.putIfAbsent(normalized, () => <int>[]).add(i);
    }
    return index;
  }

  ParsedContactRecord _parseRow(
    List<dynamic> row,
    Map<String, List<int>> headers,
  ) {
    String readValue(String key) {
      final positions = headers[key];
      if (positions == null) {
        return '';
      }
      for (final index in positions) {
        if (index >= row.length) {
          continue;
        }
        final dynamic value = row[index];
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    final displayName = readValue('displayname');
    final firstName = readValue('firstname');
    final middleName = readValue('middlename');
    final lastName = readValue('lastname');
    final prefix = readValue('title');
    final suffix = readValue('suffix');
    final nickname = readValue('nickname');

    final phoneEntries = <PhoneEntry>[];
    for (final entry in _phoneHeaderMapping.entries) {
      final value = readValue(entry.key);
      if (value.isNotEmpty) {
        phoneEntries.add(PhoneEntry(number: value, label: entry.value));
      }
    }

    final emailEntries = <EmailEntry>[];
    for (final entry in _emailHeaderMapping.entries) {
      final value = readValue(entry.key);
      if (value.isNotEmpty) {
        emailEntries.add(EmailEntry(address: value, label: entry.value));
      }
    }

    final addresses = <AddressEntry>[];
    for (final group in _addressGroups) {
      final parts = <String>[];
      for (final key in group.keys) {
        final value = readValue(key);
        if (value.isNotEmpty) {
          parts.add(value);
        }
      }
      if (parts.isEmpty) {
        continue;
      }
      final formatted = parts.toSet().toList().join(', ');
      addresses.add(AddressEntry(formatted: formatted, label: group.label));
    }

    final notes = readValue('notes');
    final company = readValue('company');
    final jobTitleValue = readValue('jobtitle');
    final jobTitle = jobTitleValue.isEmpty
        ? readValue('jobposition')
        : jobTitleValue;

    return ParsedContactRecord(
      displayName: displayName.isEmpty ? null : displayName,
      firstName: firstName.isEmpty ? null : firstName,
      middleName: middleName.isEmpty ? null : middleName,
      lastName: lastName.isEmpty ? null : lastName,
      prefix: prefix.isEmpty ? null : prefix,
      suffix: suffix.isEmpty ? null : suffix,
      nickname: nickname.isEmpty ? null : nickname,
      phones: phoneEntries,
      emails: emailEntries,
      addresses: addresses,
      notes: notes.isEmpty ? null : notes,
      company: company.isEmpty ? null : company,
      jobTitle: jobTitle.isEmpty ? null : jobTitle,
    );
  }

  String _normalizeHeader(String header) =>
      header.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
}

class ParsedContactRecord {
  const ParsedContactRecord({
    this.displayName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.prefix,
    this.suffix,
    this.nickname,
    this.company,
    this.jobTitle,
    this.notes,
    this.phones = const [],
    this.emails = const [],
    this.addresses = const [],
  });

  final String? displayName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? prefix;
  final String? suffix;
  final String? nickname;
  final String? company;
  final String? jobTitle;
  final String? notes;
  final List<PhoneEntry> phones;
  final List<EmailEntry> emails;
  final List<AddressEntry> addresses;

  bool get hasContent {
    final hasText = [
      displayName,
      firstName,
      middleName,
      lastName,
      company,
      jobTitle,
      notes,
    ].any((value) => value?.trim().isNotEmpty ?? false);
    return hasText ||
        phones.isNotEmpty ||
        emails.isNotEmpty ||
        addresses.isNotEmpty;
  }

  String? get computedDisplayName {
    final explicit = displayName?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final nameParts = [prefix, firstName, middleName, lastName, suffix]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }
    final companyName = company?.trim();
    if (companyName != null && companyName.isNotEmpty) {
      return companyName;
    }
    if (emails.isNotEmpty) {
      return emails.first.address;
    }
    if (phones.isNotEmpty) {
      return phones.first.number;
    }
    return null;
  }

  Iterable<String> get normalizedEmails => emails
      .map((entry) => entry.address.trim().toLowerCase())
      .where((value) => value.isNotEmpty);

  Iterable<String> get normalizedPhones => phones
      .map((entry) => _normalizePhone(entry.number))
      .where((value) => value.isNotEmpty);

  String? get normalizedName =>
      computedDisplayName?.trim().toLowerCase().replaceAll('  ', ' ');
}

class PhoneEntry {
  const PhoneEntry({
    required this.number,
    required this.label,
    this.customLabel,
  });

  final String number;
  final PhoneLabel label;
  final String? customLabel;
}

class EmailEntry {
  const EmailEntry({
    required this.address,
    required this.label,
    this.customLabel,
  });

  final String address;
  final EmailLabel label;
  final String? customLabel;
}

class AddressEntry {
  const AddressEntry({required this.formatted, required this.label});

  final String formatted;
  final AddressLabel label;
}

class _AddressGroup {
  const _AddressGroup({required this.keys, required this.label});

  final List<String> keys;
  final AddressLabel label;
}

class _ContactMatcher {
  _ContactMatcher(List<Contact> contacts) {
    for (final contact in contacts) {
      register(contact);
    }
  }

  final Map<String, Contact> _emailIndex = {};
  final Map<String, Contact> _phoneIndex = {};
  final Map<String, Contact> _nameIndex = {};
  final Map<String, _TrackedContactKeys> _trackedKeys = {};

  Contact? findMatch(ParsedContactRecord record) {
    for (final email in record.normalizedEmails) {
      final match = _emailIndex[email];
      if (match != null) {
        return match;
      }
    }
    for (final phone in record.normalizedPhones) {
      final match = _phoneIndex[phone];
      if (match != null) {
        return match;
      }
    }
    final nameKey = record.normalizedName;
    if (nameKey != null && nameKey.isNotEmpty) {
      return _nameIndex[nameKey];
    }
    return null;
  }

  void register(Contact contact) {
    final contactId = contact.id;
    if (contactId.isNotEmpty) {
      _removeTrackedKeys(contactId);
    } else {
      _purgeIndexesByIdentity(contact);
    }

    final emailKeys = <String>{};
    for (final email in contact.emails) {
      final key = email.address.trim().toLowerCase();
      if (key.isNotEmpty) {
        _emailIndex[key] = contact;
        emailKeys.add(key);
      }
    }

    final phoneKeys = <String>{};
    for (final phone in contact.phones) {
      final normalized = _normalizePhone(phone.number);
      if (normalized.isNotEmpty) {
        _phoneIndex[normalized] = contact;
        phoneKeys.add(normalized);
      }
      if (phone.normalizedNumber.isNotEmpty) {
        _phoneIndex[phone.normalizedNumber] = contact;
        phoneKeys.add(phone.normalizedNumber);
      }
    }

    final displayKey = contact.displayName.trim().toLowerCase();
    final nameKeys = <String>{};
    if (displayKey.isNotEmpty) {
      _nameIndex[displayKey] = contact;
      nameKeys.add(displayKey);
    }

    if (contactId.isNotEmpty) {
      _trackedKeys[contactId] = _TrackedContactKeys(
        emailKeys: emailKeys,
        phoneKeys: phoneKeys,
        nameKeys: nameKeys,
      );
    }
  }

  void _removeTrackedKeys(String contactId) {
    final tracked = _trackedKeys.remove(contactId);
    if (tracked == null) {
      return;
    }
    for (final key in tracked.emailKeys) {
      final match = _emailIndex[key];
      if (match != null && match.id == contactId) {
        _emailIndex.remove(key);
      }
    }
    for (final key in tracked.phoneKeys) {
      final match = _phoneIndex[key];
      if (match != null && match.id == contactId) {
        _phoneIndex.remove(key);
      }
    }
    for (final key in tracked.nameKeys) {
      final match = _nameIndex[key];
      if (match != null && match.id == contactId) {
        _nameIndex.remove(key);
      }
    }
  }

  void _purgeIndexesByIdentity(Contact contact) {
    _emailIndex.removeWhere((key, value) => identical(value, contact));
    _phoneIndex.removeWhere((key, value) => identical(value, contact));
    _nameIndex.removeWhere((key, value) => identical(value, contact));
  }
}

class _TrackedContactKeys {
  const _TrackedContactKeys({
    required this.emailKeys,
    required this.phoneKeys,
    required this.nameKeys,
  });

  final Set<String> emailKeys;
  final Set<String> phoneKeys;
  final Set<String> nameKeys;
}

final Map<String, PhoneLabel> _phoneHeaderMapping = {
  'mobilephone': PhoneLabel.mobile,
  'mobilephone2': PhoneLabel.workMobile,
  'businessphone': PhoneLabel.work,
  'businessphone2': PhoneLabel.work,
  'companymainphone': PhoneLabel.companyMain,
  'homephone': PhoneLabel.home,
  'homephone2': PhoneLabel.home,
  'primaryphone': PhoneLabel.main,
  'homefax': PhoneLabel.faxHome,
  'businessfax': PhoneLabel.faxWork,
  'otherfax': PhoneLabel.faxOther,
  'otherphone': PhoneLabel.other,
  'assistantphone': PhoneLabel.assistant,
  'carphone': PhoneLabel.car,
  'pager': PhoneLabel.pager,
  'radiophone': PhoneLabel.radio,
};

final Map<String, EmailLabel> _emailHeaderMapping = {
  'emailaddress': EmailLabel.work,
  'email2address': EmailLabel.home,
  'email3address': EmailLabel.other,
};

final List<_AddressGroup> _addressGroups = [
  _AddressGroup(
    keys: [
      'businessaddress',
      'businessstreet',
      'businessstreet2',
      'businessstreet3',
      'businesscity',
      'businessstate',
      'businesspostalcode',
      'businesszipcode',
      'businesscountryregion',
      'businesscountry',
    ],
    label: AddressLabel.work,
  ),
  _AddressGroup(
    keys: [
      'homeaddress',
      'homestreet',
      'homestreet2',
      'homestreet3',
      'homecity',
      'homestate',
      'homepostalcode',
      'homezipcode',
      'homecountryregion',
      'homecountry',
    ],
    label: AddressLabel.home,
  ),
  _AddressGroup(
    keys: [
      'otheraddress',
      'otherstreet',
      'otherstreet2',
      'otherstreet3',
      'othercity',
      'otherstate',
      'otherpostalcode',
      'otherzipcode',
      'othercountryregion',
      'othercountry',
    ],
    label: AddressLabel.other,
  ),
];

String _normalizePhone(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    final isDigit = char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
    if (char == '+' && buffer.isEmpty) {
      buffer.write(char);
    } else if (isDigit) {
      buffer.write(char);
    }
  }
  final normalized = buffer.toString();
  if (normalized.startsWith('00')) {
    return '+${normalized.substring(2)}';
  }
  return normalized;
}
