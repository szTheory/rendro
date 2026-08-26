const test = require('node:test');
const assert = require('node:assert/strict');
const {spawnSync} = require('node:child_process');
const {createHash} = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const phasesRoot = path.join(root, '.planning', 'phases');
const verificationPath = path.join(phasesRoot, '132-quality-baseline-triage', '132-VERIFICATION.md');
const staleVerificationSha = '1ade3d2f9e772ff2871253c435662fb33b146d13f61c54d8422e2ec7d13b2dfd';
const staleVerificationCommit = 'be640780df7852387b493b392b7eb148308ea01b';
const ids = ['PROH-132-01', 'PROH-132-02', 'PROH-132-03'];
const expectedKinds = {
  violation: ['authority_inflation', 'consumer_leak', 'metric_only_authority'],
  clean: ['unavailable_semantics', 'approved_consumer', 'evidence_gated_decision']
};

function readManifest(relativePath, flavor) {
  if (path.isAbsolute(relativePath) || relativePath.split(/[\\/]/).includes('..')) {
    throw new Error('fixture path must be repository-relative without traversal');
  }

  const manifest = JSON.parse(fs.readFileSync(path.join(root, relativePath), 'utf8'));
  assert.deepEqual(Object.keys(manifest).sort(), ['cases', 'version']);
  assert.equal(manifest.version, 1);
  assert.deepEqual(Object.keys(manifest.cases).sort(), ids);

  ids.forEach((id, index) => {
    const item = manifest.cases[id];
    assert.deepEqual(Object.keys(item).sort(), ['kind']);
    assert.equal(item.kind, expectedKinds[flavor][index]);
  });

  return manifest;
}

function validateVirtualArtifact(kind, flavor) {
  const valid = new Set(expectedKinds[flavor]);
  if (!valid.has(kind)) return false;

  if (flavor === 'violation') {
    return false;
  }

  return true;
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
  }

  if (name.endsWith('-UAT.md') && (/(?:status:\s*)?(?:pending|awaiting)/i.test(text) || /human_judgment:\s*true/i.test(text))) {
    blockers.push(`${rel}: pending or human-needed UAT`);
  }

  if (name.endsWith('-VALIDATION.md') && /(pending|manual-only|human[_ -]?(?:needed|verification)|awaiting)/i.test(text)) {
    blockers.push(`${rel}: pending/manual validation sign-off`);
  }

  if (name.endsWith('-VERIFICATION.md') && /human[_ -]?(?:needed|verification)/i.test(text) && !stagingAllowed) {
    blockers.push(`${rel}: human verification remains active`);
  }

  if (name.endsWith('-SUMMARY.md') && /human_judgment:\s*true/i.test(text)) {
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
    .flatMap((file) => blockersForFile(file, stagingAllowed));

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
      assert.equal(validateVirtualArtifact(violation.cases[id].kind, 'violation'), false);
      assert.equal(validateVirtualArtifact(clean.cases[id].kind, 'clean'), true);
    });
  });

  test('fixtures reject unknown fields, missing pairs, traversal, and snapshot override inputs', () => {
    assert.throws(() => readManifest('../test/quality/fixtures/governance-clean.json', 'clean'));
    assert.equal(validateVirtualArtifact('snapshot_write', 'clean'), false);
    assert.equal(validateVirtualArtifact('override_source_sha', 'clean'), false);
  });

  test('full mode rejects the currently active governance backlog', () => {
    assert.throws(() => checkActive([]), /active governance blockers/);
    assert.deepEqual(blockersForFile(path.join(phasesRoot, '132-quality-baseline-triage', '132-03-PLAN.md'), false), []);
  });

  test('staging mode accepts no arbitrary stale verification identity', () => {
    assert.equal(hasPinnedStaleVerificationException(['--allow-stale-verification-sha', '0'.repeat(64), '--allow-stale-verification-source-commit', staleVerificationCommit]), false);
    assert.equal(hasPinnedStaleVerificationException(['--allow-stale-verification-sha', staleVerificationSha, '--allow-stale-verification-source-commit', '0'.repeat(40)]), false);
  });
}
