import 'package:flutter_test/flutter_test.dart';
import 'package:jobwink/services/job_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Job Openings & Randomization Tests', () {
    test('1. fetchLatest48hJobs returns at least 10 unique jobs', () async {
      final jobs = await JobService.instance.fetchLatest48hJobs(forceRefresh: true);

      expect(jobs.length, greaterThanOrEqualTo(10),
          reason: 'Job service must guarantee at least 10 job openings');

      // Verify no duplicates
      final ids = jobs.map((j) => j.id).toSet();
      final urls = jobs.map((j) => j.applyUrl ?? j.jobUrl ?? '').where((u) => u.isNotEmpty).toSet();
      final combos = jobs.map((j) => '${j.companyName.toLowerCase()}|${j.jobTitle.toLowerCase()}').toSet();

      expect(ids.length, jobs.length, reason: 'Every job must have a unique ID');
      expect(urls.length, jobs.length, reason: 'Every job must have a unique URL');
      expect(combos.length, jobs.length, reason: 'Every job must have a unique company+title combo');
    });

    test('2. All job openings have valid required fields and official apply URLs', () async {
      final jobs = await JobService.instance.fetchLatest48hJobs();

      for (final job in jobs) {
        expect(job.jobTitle.trim().isNotEmpty, isTrue, reason: 'Job title cannot be empty');
        expect(job.jobTitle != 'Untitled Position', isTrue, reason: 'Job title must be valid');
        expect(job.companyName.trim().isNotEmpty, isTrue, reason: 'Company name cannot be empty');
        expect(job.companyName != 'Company', isTrue, reason: 'Company name must be valid');
        expect(job.location.trim().isNotEmpty, isTrue, reason: 'Location cannot be empty');
        expect(job.description.trim().isNotEmpty, isTrue, reason: 'Description cannot be empty');
        expect(job.applyUrl != null && job.applyUrl!.startsWith('http'), isTrue,
            reason: 'Apply URL must be a valid http link');
        expect(job.matchingSkills, isNotEmpty, reason: 'Matching skills must be populated');
        expect(job.matchPercentage, greaterThan(50.0), reason: 'Match percentage must be positive');
      }
    });

    test('3. Refreshing feed produces randomized order across sessions', () async {
      final batch1 = await JobService.instance.fetchLatest48hJobs(forceRefresh: true);
      final batch2 = await JobService.instance.fetchLatest48hJobs(forceRefresh: true);

      expect(batch1.length, greaterThanOrEqualTo(10));
      expect(batch2.length, greaterThanOrEqualTo(10));

      final titles1 = batch1.map((j) => j.jobTitle).toList();
      final titles2 = batch2.map((j) => j.jobTitle).toList();

      // Over 20 items, a random shuffle is astronomically unlikely to produce identical order
      expect(titles1, isNot(equals(titles2)),
          reason: 'Refreshing the feed must randomize the job presentation order');
    });
  });
}
