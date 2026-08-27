const test = require('node:test');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const {createHash} = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const phasesRoot = path.join(root, '.planning', 'phases');
const verificationPath = path.join(phasesRoot, '132-quality-baseline-triage', '132-VERIFICATION.md');
const staleVerificationSha = '1ade3d2f9e772ff2871253c435662fb33b146d13f61c54d8422e2ec7d13b2dfd';
const staleVerificationCommit = 'be640780df7852387b493b392b7eb148308ea01b';
const ids = ['PROH-132-01', 'PROH-132-02', 'PROH-132-03'];
const ledgerReference = /\.planning\/(?:QUALITY\.md|quality\/baselines\/132-initial\.json)/;
const approvedLedgerConsumers = new Set(['test/quality/baseline_ledger_contract_test.exs']);
const excludedConsumerDirectories = new Set(['_build', 'deps', 'node_modules', '.cache', 'cache', '.git', '.hg', '.svn']);
const humanStatePatterns = [
  /^\s*(?:-\s*)?human_judgment\s*:\s*true\b/im,
  /^\s*(?:-\s*)?human_needed(?:\s*:\s*true\b|\s*)$/im,
  /^\s*(?:-\s*)?human_verification(?:\s*:\s*true\b|\s*)$/im
];

function hasProhibitedHumanState(text) {
  return humanStatePatterns.some((pattern) => pattern.test(text));
}

function frontmatterStatus(text) {
  const match = text.match(/^---\s*\n([\s\S]*?)\n---/);
  const status = match?.[1].match(/^status:\s*(\S+)\s*$/m);
  return status?.[1] || null;
}

function assertRepositoryRelative(relativePath) {
  if (typeof relativePath !== 'string' || path.isAbsolute(relativePath) || relativePath.split(/[\\/]/).includes('..')) {
    throw new Error('fixture path must be repository-relative without traversal');
  }
}

function readManifest(relativePath, flavor) {
  assertRepositoryRelative(relativePath);

  const manifest = JSON.parse(fs.readFileSync(path.join(root, relativePath), 'utf8'));
  assert.deepEqual(Object.keys(manifest).sort(), ['cases', 'version']);
  assert.equal(manifest.version, 1);
  assert.deepEqual(Object.keys(manifest.cases).sort(), ids);

  ids.forEach((id, index) => {
    const item = manifest.cases[id];
    assert.deepEqual(Object.keys(item).sort(), ['artifact']);
    assert.deepEqual(Object.keys(item.artifact).sort(), ['path', 'text']);
    assertRepositoryRelative(item.artifact.path);
    assert.equal(typeof item.artifact.text, 'string');
  });

  return manifest;
}

function governanceMarkers(text) {
  return [...text.matchAll(/<!--\s*quality-governance:\s*({[^>]*})\s*-->/g)].map((match) => JSON.parse(match[1]));
}

function validateGovernanceMarker(marker, relativePath) {
  assertRepositoryRelative(relativePath);
  if (!marker || typeof marker !== 'object' || Array.isArray(marker)) return false;

  if (marker.role === 'authority') {
    return marker.basis === 'explicit_unavailability' && marker.primary_ci === false;
  }

  if (marker.role === 'consumer') {
    return marker.reference === '.planning/QUALITY.md' && approvedLedgerConsumers.has(relativePath);
  }

  if (marker.role === 'decision') {
    return ['supported_contract_risk', 'bounded_maintenance_cost'].includes(marker.basis) &&
      ['repair', 'closed'].includes(marker.disposition) && marker.evidence_gated === true;
  }

  return false;
}

function validateArtifact(artifact) {
  assertRepositoryRelative(artifact.path);
  if (typeof artifact.text !== 'string') return false;
  const markers = governanceMarkers(artifact.text);
  return markers.length === 1 && validateGovernanceMarker(markers[0], artifact.path);
}

function runBaseline() {
  const result = spawnSync('mix', ['quality.baseline'], {
    cwd: root,
    env: {...process.env, MIX_ENV: 'test'},
    shell: false,
    encoding: 'utf8'
  });

  if (result.error) throw result.error;
  assert.equal(result.status, 0, result.stderr || result.stdout);
}

function activePhaseDirectories() {
  return fs.readdirSync(phasesRoot, {withFileTypes: true})
    .filter((entry) => entry.isDirectory() && /^(\d+)-/.test(entry.name))
    .filter((entry) => Number.parseInt(entry.name, 10) >= 132)
    .map((entry) => path.join(phasesRoot, entry.name));
}

function markdownFiles(directory) {
  return fs.readdirSync(directory, {withFileTypes: true})
    .filter((entry) => entry.isFile() && entry.name.endsWith('.md'))
    .map((entry) => path.join(directory, entry.name));
}

function isInsideRepository(candidate) {
  const relative = path.relative(root, candidate);
  return relative === '' || (!relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative));
}

function resolvedSymlinkFile(candidate) {
  const rel = path.relative(root, candidate);
  let resolved;

  try {
    resolved = fs.realpathSync(candidate);
  } catch (error) {
    throw new Error(`${rel}: in-scope symlink cannot be resolved (${error.code || error.message})`);
  }

  if (!isInsideRepository(resolved)) {
    throw new Error(`${rel}: in-scope symlink resolves outside the repository`);
  }

  let stats;
  try {
    stats = fs.statSync(resolved);
  } catch (error) {
    throw new Error(`${rel}: in-scope symlink target cannot be inspected (${error.code || error.message})`);
  }

  if (!stats.isFile()) throw new Error(`${rel}: in-scope symlink must resolve to a regular file`);
  return candidate;
}

function filesRecursively(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap((entry) => {
    if (excludedConsumerDirectories.has(entry.name)) return [];
    const candidate = path.join(directory, entry.name);
    if (entry.isSymbolicLink()) return [resolvedSymlinkFile(candidate)];
    if (entry.isDirectory()) return filesRecursively(candidate);
    return entry.isFile() ? [candidate] : [];
  });
}

function consumerSurfaceFiles() {
  return [
    path.join(root, 'mix.exs'),
    path.join(root, 'package.json'),
    path.join(root, '.github', 'workflows', 'release.yml'),
    ...filesRecursively(path.join(root, 'lib')),
    ...filesRecursively(path.join(root, 'dev')),
    ...filesRecursively(path.join(root, 'examples')),
    ...filesRecursively(path.join(root, 'test')).filter((file) => {
      const rel = path.relative(root, file);
      return rel !== 'test/quality/baseline_ledger_contract_test.exs' && !rel.startsWith('test/quality/fixtures/');
    })
  ].filter((file) => fs.existsSync(file));
}

function consumerBlockers() {
  return consumerSurfaceFiles().flatMap((file) => {
    const text = fs.readFileSync(file, 'utf8');
    if (!ledgerReference.test(text)) return [];
    const rel = path.relative(root, file);
    return validateGovernanceMarker({role: 'consumer', reference: '.planning/QUALITY.md'}, rel) ? [] :
      [`${rel}: unapproved ledger consumer`];
  });
}

function markerBlockers(file) {
  const rel = path.relative(root, file);
  return governanceMarkers(fs.readFileSync(file, 'utf8'))
    .filter((marker) => !validateGovernanceMarker(marker, rel))
    .map(() => `${rel}: prohibited governance state`);
}

function hasPinnedStaleVerificationException(args) {
  if (args.length !== 4 ||
      args[0] !== '--allow-stale-verification-sha' ||
      args[1] !== staleVerificationSha ||
      args[2] !== '--allow-stale-verification-source-commit' ||
      args[3] !== staleVerificationCommit) {
    return false;
  }

  const bytes = fs.readFileSync(verificationPath);
  const digest = createHash('sha256').update(bytes).digest('hex');
  if (digest !== staleVerificationSha) return false;

  const owner = spawnSync('git', ['log', '-1', '--format=%H', '--', verificationPath], {
    cwd: root,
    shell: false,
    encoding: 'utf8'
  });

  return owner.status === 0 && owner.stdout.trim() === staleVerificationCommit;
}

function blockersForFile(file, stagingAllowed) {
  const text = fs.readFileSync(file, 'utf8');
  const name = path.basename(file);
  const rel = path.relative(root, file);
  const blockers = [];

  if (name.endsWith('-PLAN.md')) {
    const verificationBlocks = [...text.matchAll(/<verify>([\s\S]*?)<\/verify>/gi)].map((match) => match[1]);

    if (verificationBlocks.some((block) => /<human-check\b/i.test(block)) || /<task type="checkpoint:human-verify"/i.test(text)) {
      blockers.push(`${rel}: unresolved human verification checkpoint`);
    }
    if (/gate="blocking(?:-human)?"/i.test(text) && /<task type="checkpoint/i.test(text)) {
      blockers.push(`${rel}: unresolved blocking backstop`);
    }
    if (/PROH-132-\d{2}[\s\S]{0,500}check_kind:\s*(?:null|flagged|human)/i.test(text)) {
      blockers.push(`${rel}: descriptor-less prohibition`);
    }
    if (hasProhibitedHumanState(text)) {
      blockers.push(`${rel}: blocking human state remains active`);
    }
  }

  if (name.endsWith('-UAT.md') && (/(?:status:\s*)?(?:pending|awaiting)/i.test(text) || hasProhibitedHumanState(text))) {
    blockers.push(`${rel}: pending or human-needed UAT`);
  }

  if (name.endsWith('-VALIDATION.md') && frontmatterStatus(text) !== 'draft' &&
      (/(pending|manual-only|awaiting)/i.test(text) || hasProhibitedHumanState(text))) {
    blockers.push(`${rel}: pending/manual validation sign-off`);
  }

  if (name.endsWith('-VERIFICATION.md') && hasProhibitedHumanState(text) && !stagingAllowed) {
    blockers.push(`${rel}: human verification remains active`);
  }

  if (name.endsWith('-SUMMARY.md') && hasProhibitedHumanState(text)) {
    blockers.push(`${rel}: summary retains human-needed coverage`);
  }

  return blockers;
}

function checkActive(args) {
  const stagingAllowed = hasPinnedStaleVerificationException(args);
  if (args.length > 0 && !stagingAllowed) {
    throw new Error('stale verification exception must be the one exact path/hash/source-commit pair');
  }

  const blockers = activePhaseDirectories()
    .flatMap(markdownFiles)
    .flatMap((file) => [...blockersForFile(file, stagingAllowed), ...markerBlockers(file)]);

  blockers.push(...consumerBlockers());

  if (blockers.length > 0) throw new Error(`active governance blockers:\n${blockers.join('\n')}`);
}

function main(args) {
  if (args[0] !== '--check-active') {
    throw new Error('usage: node scripts/quality_governance.cjs --check-active [staging exception]');
  }
  checkActive(args.slice(1));
}

if (process.argv[2] === '--check-active') {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
} else {
  test('each closed prohibition fixture runs the baseline through a shell-free argv bridge', () => {
    const violation = readManifest('test/quality/fixtures/governance-violation.json', 'violation');
    const clean = readManifest('test/quality/fixtures/governance-clean.json', 'clean');

    ids.forEach((id) => {
      runBaseline();
      assert.equal(validateArtifact(violation.cases[id].artifact), false);
      assert.equal(validateArtifact(clean.cases[id].artifact), true);
    });
  });

  test('fixtures reject unknown fields, missing pairs, traversal, and snapshot override inputs', () => {
    assert.throws(() => readManifest('../test/quality/fixtures/governance-clean.json', 'clean'));
    assert.throws(() => validateArtifact({path: '../.planning/QUALITY.md', text: ''}));
    assert.equal(validateArtifact({path: '.planning/quality/baselines/132-initial.json', text: '<!-- quality-governance: {"role":"snapshot_write"} -->'}), false);
  });

  test('CLI rejects inserted authority, consumer, and decision violations', () => {
    const mutations = [
      ['.planning/phases/132-quality-baseline-triage/132-GOVERNANCE-MUTATION.md', '<!-- quality-governance: {"role":"authority","basis":"local_advisory","primary_ci":true} -->'],
      ['lib/rendro/governance_mutation.ex', '# .planning/QUALITY.md'],
      ['.planning/phases/132-quality-baseline-triage/132-GOVERNANCE-MUTATION.md', '<!-- quality-governance: {"role":"decision","basis":"diagnostic_signal_only","disposition":"repair","evidence_gated":false} -->']
    ];

    for (const [relativePath, text] of mutations) {
      const file = path.join(root, relativePath);
      fs.writeFileSync(file, text);
      try {
        const result = spawnSync(process.execPath, [__filename, '--check-active'], {cwd: root, shell: false, encoding: 'utf8'});
        assert.notEqual(result.status, 0, `${relativePath} mutation must fail active governance`);
      } finally {
        fs.rmSync(file, {force: true});
      }
    }
  });

  test('consumer scan skips generated directory symlinks but still rejects regular in-scope consumers', () => {
    const examplesRoot = path.join(root, 'examples', 'phoenix_example');
    const target = fs.mkdtempSync(path.join(os.tmpdir(), 'rendro-governance-symlink-'));
    const generatedRoot = path.join(examplesRoot, '.quality-governance-generated');
    const symlink = path.join(generatedRoot, '_build');
    const regularConsumer = path.join(examplesRoot, '.quality-governance-consumer.ex');
    fs.writeFileSync(path.join(target, 'consumer.ex'), '# .planning/QUALITY.md');
    fs.mkdirSync(generatedRoot);
    fs.symlinkSync(target, symlink, process.platform === 'win32' ? 'junction' : 'dir');

    try {
      assert.doesNotThrow(() => checkActive([]));
      fs.writeFileSync(regularConsumer, '# .planning/QUALITY.md');
      assert.throws(() => checkActive([]), /unapproved ledger consumer/);
    } finally {
      fs.rmSync(regularConsumer, {force: true});
      fs.rmSync(symlink, {force: true});
      fs.rmSync(generatedRoot, {recursive: true, force: true});
      fs.rmSync(target, {recursive: true, force: true});
    }
  });

  test('consumer scan follows an in-repository regular-file symlink under its consumer path', () => {
    const examplesRoot = path.join(root, 'examples', 'phoenix_example');
    const generatedRoot = path.join(examplesRoot, '.quality-governance-symlink-target', '_build');
    const target = path.join(generatedRoot, 'consumer.ex');
    const symlink = path.join(examplesRoot, '.quality-governance-regular-link.ex');
    fs.mkdirSync(generatedRoot, {recursive: true});
    fs.writeFileSync(target, '# .planning/QUALITY.md');
    fs.symlinkSync(target, symlink, 'file');

    try {
      assert.throws(() => checkActive([]), /\.quality-governance-regular-link\.ex: unapproved ledger consumer/);
    } finally {
      fs.rmSync(symlink, {force: true});
      fs.rmSync(path.join(examplesRoot, '.quality-governance-symlink-target'), {recursive: true, force: true});
    }
  });

  test('consumer scan fails closed for outside and dangling in-scope symlinks', {skip: process.platform === 'win32'}, () => {
    const examplesRoot = path.join(root, 'examples', 'phoenix_example');
    const outsideTarget = fs.mkdtempSync(path.join(os.tmpdir(), 'rendro-governance-outside-'));
    const outsideLink = path.join(examplesRoot, '.quality-governance-outside-link.ex');
    const danglingLink = path.join(examplesRoot, '.quality-governance-dangling-link.ex');
    fs.writeFileSync(path.join(outsideTarget, 'consumer.ex'), '# .planning/QUALITY.md');
    fs.symlinkSync(path.join(outsideTarget, 'consumer.ex'), outsideLink, 'file');

    try {
      assert.throws(() => checkActive([]), /outside-link\.ex: in-scope symlink resolves outside the repository/);
      fs.rmSync(outsideLink, {force: true});
      fs.symlinkSync(path.join(examplesRoot, '.quality-governance-missing-target.ex'), danglingLink, 'file');
      assert.throws(() => checkActive([]), /dangling-link\.ex: in-scope symlink cannot be resolved/);
    } finally {
      fs.rmSync(outsideLink, {force: true});
      fs.rmSync(danglingLink, {force: true});
      fs.rmSync(outsideTarget, {recursive: true, force: true});
    }
  });

  test('CLI rejects every blocking human state in terminal artifacts without rejecting advisory prose', () => {
    const phaseDirectory = path.join(phasesRoot, '133-governance-mutations');
    fs.mkdirSync(phaseDirectory, {recursive: true});
    const roles = ['PLAN', 'UAT', 'SUMMARY', 'VALIDATION', 'VERIFICATION'];
    const states = ['human_judgment: true', 'human_needed: true', 'human_verification: true'];

    try {
      for (const role of roles) {
        for (const state of states) {
          const file = path.join(phaseDirectory, `133-GOVERNANCE-${role}.md`);
          fs.writeFileSync(file, `${state}\n`);
          const result = spawnSync(process.execPath, [__filename, '--check-active'], {cwd: root, shell: false, encoding: 'utf8'});
          assert.notEqual(result.status, 0, `${role} ${state} must fail active governance`);
          fs.rmSync(file, {force: true});
        }
      }

      const advisory = path.join(phaseDirectory, '133-GOVERNANCE-SUMMARY.md');
      fs.writeFileSync(advisory, 'Optional human feedback is advisory.\nhuman_needed: false\nhuman_verification: false\n');
      assert.equal(spawnSync(process.execPath, [__filename, '--check-active'], {cwd: root, shell: false}).status, 0);
    } finally {
      fs.rmSync(phaseDirectory, {recursive: true, force: true});
    }
  });

  test('full mode accepts terminal phase artifacts without a stale exception', () => {
    assert.doesNotThrow(() => checkActive([]));
    assert.deepEqual(blockersForFile(path.join(phasesRoot, '132-quality-baseline-triage', '132-03-PLAN.md'), false), []);
  });

  test('staging mode accepts no arbitrary stale verification identity', () => {
    assert.equal(hasPinnedStaleVerificationException(['--allow-stale-verification-sha', '0'.repeat(64), '--allow-stale-verification-source-commit', staleVerificationCommit]), false);
    assert.equal(hasPinnedStaleVerificationException(['--allow-stale-verification-sha', staleVerificationSha, '--allow-stale-verification-source-commit', '0'.repeat(40)]), false);
  });

  test('quality baseline is process-repeatable without changing authoritative bytes', () => {
    const ledger = path.join(root, '.planning', 'QUALITY.md');
    const snapshot = path.join(root, '.planning', 'quality', 'baselines', '132-initial.json');
    const before = [fs.readFileSync(ledger), fs.readFileSync(snapshot)];

    for (let run = 0; run < 2; run++) {
      const result = spawnSync('mix', ['quality.baseline'], {cwd: root, shell: false, encoding: 'utf8'});
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual([fs.readFileSync(ledger), fs.readFileSync(snapshot)], before);
    }
  });
}
