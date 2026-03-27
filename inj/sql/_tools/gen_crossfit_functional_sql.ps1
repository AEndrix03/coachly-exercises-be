$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Esc([string]$s) { if ($null -eq $s) { return "" }; return ($s -replace "'", "''") }

function Snake([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return "" }
    $x = $s.ToLowerInvariant()
    $x = $x -replace "&", " and "
    $x = $x -replace "[^a-z0-9]+", "_"
    $x = $x -replace "_{2,}", "_"
    return $x.Trim("_")
}

function DiffLevel([string]$d) {
    switch ($d) {
        "beginner" { 1 }
        "intermediate" { 2 }
        "advanced" { 3 }
        "elite" { 4 }
        default { 2 }
    }
}

function MuscleCode([string]$raw) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    $n = ($raw.Trim().ToLowerInvariant() -replace "\s+", " ")

    if ($n -match "pectoralis major" -and $n -match "upper|clavicular") { return "pec_major_upper" }
    if ($n -match "pectoralis major" -and $n -match "mid|sternal") { return "pec_major_mid" }
    if ($n -match "pectoralis major" -and $n -match "lower|costal") { return "pec_major_lower" }
    if ($n -eq "pectoralis minor") { return "pec_minor" }
    if ($n -eq "serratus anterior") { return "serratus_anterior" }

    if ($n -eq "latissimus dorsi") { return "lat_dorsi" }
    if ($n -match "trapezius" -and $n -match "upper") { return "trap_upper" }
    if ($n -match "trapezius" -and $n -match "mid|middle") { return "trap_mid" }
    if ($n -match "trapezius" -and $n -match "lower") { return "trap_lower" }
    if ($n -eq "teres major") { return "teres_major" }
    if ($n -eq "erector spinae") { return "erector_spinae" }

    if ($n -match "deltoid" -and $n -match "anterior") { return "deltoid_anterior" }
    if ($n -match "deltoid" -and $n -match "lateral") { return "deltoid_lateral" }
    if ($n -match "deltoid" -and $n -match "posterior") { return "deltoid_posterior" }
    if ($n -eq "subscapularis") { return "subscapularis" }

    if ($n -match "biceps brachii" -and $n -match "long") { return "biceps_long_head" }
    if ($n -match "biceps brachii" -and $n -match "short") { return "biceps_short_head" }
    if ($n -eq "brachialis") { return "brachialis" }
    if ($n -eq "brachioradialis") { return "brachioradialis" }

    if ($n -match "triceps brachii" -and $n -match "long") { return "triceps_long_head" }
    if ($n -match "triceps brachii" -and $n -match "lateral") { return "triceps_lateral_head" }
    if ($n -match "triceps brachii" -and $n -match "medial") { return "triceps_medial_head" }

    if ($n -eq "rectus abdominis") { return "rectus_abdominis" }
    if ($n -eq "external oblique") { return "external_oblique" }
    if ($n -eq "internal oblique") { return "internal_oblique" }
    if ($n -match "transversus abdominis|transverse abdominis") { return "transversus_abdom" }

    if ($n -eq "rectus femoris") { return "rectus_femoris" }
    if ($n -eq "vastus lateralis") { return "vastus_lateralis" }
    if ($n -eq "vastus medialis") { return "vastus_medialis" }
    if ($n -eq "gluteus maximus") { return "gluteus_maximus" }
    if ($n -eq "gluteus medius") { return "gluteus_medius" }
    if ($n -eq "semitendinosus") { return "semitendinosus" }
    if ($n -eq "semimembranosus") { return "semimembranosus" }

    if ($n -match "gastrocnemius" -and $n -match "medial") { return "gastrocnemius_medial" }
    if ($n -match "gastrocnemius" -and $n -match "lateral") { return "gastrocnemius_lateral" }
    if ($n -eq "soleus") { return "soleus" }

    return $null
}

function EquipCode([string]$raw, [bool]$bw) {
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    $t = ($raw.Trim().ToLowerInvariant() -replace "\s+", " ")

    if ($t -match "none \(bodyweight\)|bodyweight|floor|wall") { if ($bw) { return "none_bodyweight" } }
    if ($t -match "^barbell$") { return "barbell" }
    if ($t -match "dumbbell") { return "dumbbell" }
    if ($t -match "kettlebell") { return "kettlebell" }
    if ($t -match "gymnastic rings|rings") { return "gymnastic_rings" }
    if ($t -match "pull[- ]?up bar|\\bbar\\b") { return "pull_up_bar" }
    if ($t -match "bench") { return "flat_bench" }
    if ($t -match "box") { return "box_platform" }
    if ($t -match "wall ball") { return "wall_ball" }
    if ($t -match "medicine ball") { return "medicine_ball" }
    if ($t -match "assault bike|air bike") { return "assault_bike" }
    if ($t -match "row(ing)? machine|rower") { return "rowing_machine" }
    if ($t -match "jump rope") { return "jump_rope" }
    if ($t -match "battle ropes") { return "battle_ropes" }
    if ($t -match "cable") { return "cable_machine" }
    if ($t -match "band") { return "resistance_band" }

    return $null
}

function UnilateralByName([string]$name) { return ($name -match "(?i)single[- ]arm|single[- ]leg|one[- ]arm|one[- ]leg|unilateral") }

function DescEN([string]$name) {
    switch -Regex ($name) {
        "(?i)clean\\s*&\\s*jerk|clean\\s+and\\s+jerk" { "Pull from the floor into a strong rack, stand tall, then dip-drive into the jerk. Keep the bar close, brace hard, and finish with locked elbows overhead before recovering under control." }
        "(?i)push\\s+press" { "From a solid front rack, dip a few inches with a tall torso, then drive and press overhead to full lockout. Lower to the rack under control and reset your brace each rep." }
        "(?i)push\\s+jerk|split\\s+jerk" { "Dip and drive from the rack, then receive the bar overhead with locked elbows and stable shoulders. Keep the bar path vertical and recover to a strong standing position before the next rep." }
        "(?i)thruster" { "Front rack the load, squat to depth, then drive up and transition immediately into an overhead press. Keep the core braced and finish each rep with a stable lockout." }
        "(?i)overhead\\s+squat" { "Hold the bar overhead with active shoulders and squat with the load stacked over midfoot. Keep a neutral spine, knees tracking, and consistent bar position through the full range." }
        "(?i)front\\s+squat|back\\s+squat|air\\s+squat" { "Brace, descend under control to depth, and keep knees tracking over toes with heels down. Drive up through midfoot and keep the torso position consistent throughout." }
        "(?i)deadlift" { "Set the bar over midfoot, brace, and push the floor away while keeping the bar close to the body. Stand tall to lock out without overextending the lower back, then lower under control." }
        "(?i)pull[- ]?up|chin[- ]?up|chest[- ]?to[- ]?bar" { "Start from a dead hang with shoulders engaged, then pull by driving elbows down and back. Reach the target height with control and lower to a full hang without losing tension." }
        "(?i)burpee" { "Drop to the floor with hands under shoulders, complete the chest-to-floor portion with control, then snap feet under hips and jump tall. Keep breathing steady and land softly each rep." }
        "(?i)box\\s+jump" { "Load the hips, jump onto the box with a soft, stable landing, and stand fully on top. Step down under control to reduce Achilles stress and keep reps crisp." }
        "(?i)plank|dead bug|bird dog" { "Maintain ribs down and a braced core while moving slowly through the pattern. Keep hips square and avoid losing spinal position; use controlled breathing to hold tension." }
        default { "Set up in a stable position and brace the core. Move through a controlled range of motion with good alignment, then reset deliberately between reps to keep technique consistent." }
    }
}

function DescIT([string]$name) {
    switch -Regex ($name) {
        "(?i)clean\\s*&\\s*jerk|clean\\s+and\\s+jerk" { "Tira da terra fino al front rack solido, estendi in alto e poi esegui dip-drive e jerk. Mantieni il bilanciere vicino, bracing forte e chiudi in overhead con gomiti bloccati prima di recuperare." }
        "(?i)push\\s+press" { "Dal front rack fai un piccolo dip con busto alto e poi spingi e pressa in overhead fino al lockout. Riporta in rack controllato e resetta il bracing a ogni ripetizione." }
        "(?i)push\\s+jerk|split\\s+jerk" { "Esegui dip e drive dal rack e ricevi il bilanciere in overhead con gomiti bloccati e spalle stabili. Tieni traiettoria verticale e recupera in stazione eretta prima della ripetizione successiva." }
        "(?i)thruster" { "Carico in front rack, scendi in squat fino a profondita e risali trasformando subito la spinta in press overhead. Core attivo e lockout stabile in alto prima di ripartire." }
        "(?i)overhead\\s+squat" { "Bilanciere in overhead con spalle attive, poi esegui lo squat mantenendo il carico sopra meta piede. Schiena neutra, ginocchia in linea e posizione del bilanciere costante per tutto il ROM." }
        "(?i)front\\s+squat|back\\s+squat|air\\s+squat" { "Bracing, discesa controllata fino a profondita e ginocchia in linea con le punte con talloni a terra. Risali spingendo a meta piede mantenendo la posizione del busto." }
        "(?i)deadlift" { "Bilanciere sopra meta piede, bracing e poi spingi il pavimento tenendo il bilanciere vicino alle gambe. Chiudi in estensione senza iperestendere e scendi controllato." }
        "(?i)pull[- ]?up|chin[- ]?up|chest[- ]?to[- ]?bar" { "Parti da dead hang con spalle attive e tira portando i gomiti in basso e indietro. Raggiungi l'altezza target in controllo e scendi fino a estensione completa senza perdere tensione." }
        "(?i)burpee" { "Scendi a terra con mani sotto le spalle, controlla la fase petto-a-terra, poi riporta i piedi sotto il bacino e salta in estensione. Mantieni ritmo respiratorio e atterra morbido." }
        "(?i)box\\s+jump" { "Carica le anche, salta sul box atterrando morbido e stabile e poi estendi in alto. Scendi con step-down controllato per ridurre stress su tendini e mantenere qualita delle reps." }
        "(?i)plank|dead bug|bird dog" { "Mantieni coste giu e core attivo mentre esegui lentamente il pattern. Bacino in squadra e assetto della colonna stabile; usa respirazione controllata per mantenere tensione." }
        default { "Imposta una posizione stabile e crea bracing. Muoviti in ROM controllato con buoni allineamenti, poi resetta con intenzione tra le ripetizioni per mantenere tecnica consistente." }
    }
}

function Tags([string]$category, [string]$name, [string]$mechanics, [string]$force, [bool]$uni, [bool]$bw, [string[]]$equip, [string]$risk, [bool]$spot, [string]$diff) {
    $t = New-Object System.Collections.Generic.List[string]
    $add = { param([string]$x) if (-not [string]::IsNullOrWhiteSpace($x) -and -not $t.Contains($x)) { [void]$t.Add($x) } }
    & $add $mechanics
    if ($force -eq "static") { & $add "isometric" }
    if ($name -match "(?i)jump") { & $add "plyometric" }
    if ($name -match "(?i)clean|snatch|jerk") { & $add "explosive" }

    if ($name -match "(?i)bench|push[- ]?up|dip") { & $add "horizontal_push" }
    if ($name -match "(?i)overhead|handstand|jerk|push press") { & $add "vertical_push" }
    if ($name -match "(?i)row") { & $add "horizontal_pull" }
    if ($name -match "(?i)pull[- ]?up|chin[- ]?up|toes[- ]?to[- ]?bar|muscle[- ]?up") { & $add "vertical_pull" }
    if ($name -match "(?i)deadlift|swing|hip thrust|pull[- ]?through") { & $add "hip_hinge" }
    if ($name -match "(?i)squat|lunge|step[- ]?up") { & $add "knee_dominant" }
    if ($name -match "(?i)plank|dead bug|bird dog") { & $add "core_focus" }

    if ($uni) { & $add "unilateral" } else { & $add "bilateral" }

    if ($equip -contains "barbell") { & $add "barbell_tag" }
    if ($equip -contains "dumbbell") { & $add "dumbbell_tag" }
    if ($equip -contains "kettlebell") { & $add "kettlebell_tag" }
    if ($equip -contains "cable_machine") { & $add "cable_tag" }
    if ($equip -contains "gymnastic_rings") { & $add "rings_tag" }
    if ($equip -contains "resistance_band") { & $add "band_tag" }
    if ($bw -or $equip -contains "none_bodyweight") { & $add "no_equipment" }

    if ($spot) { & $add "spotter_needed" }
    if ($risk -match "high|very_high") { & $add "high_risk" }
    if ($diff -match "advanced|elite") { & $add "advanced_only" }
    if ($category -eq "crossfit") { & $add "crossfit_movement" }

    # keep 4-8
    return $t | Select-Object -First 8
}

function BuildSql(
    [string]$category,
    [string]$en,
    [string]$it,
    [string]$difficulty,
    [string]$mechanics,
    [string]$force,
    [bool]$uni,
    [bool]$bw,
    [string]$risk,
    [bool]$spot,
    [string[]]$pm,
    [string[]]$sm,
    [string[]]$equip,
    [object[]]$vars
) {
    $enDesc = Esc (DescEN $en)
    $itDesc = Esc (DescIT $en)

    $tagList = (Tags $category $en $mechanics $force $uni $bw $equip $risk $spot $difficulty | ForEach-Object { "'$_'" }) -join ","

    $out = New-Object System.Text.StringBuilder
    [void]$out.AppendLine("-- =============================================================")
    [void]$out.AppendLine("-- Exercise: $en")
    [void]$out.AppendLine("-- Disciplines: $category")
    [void]$out.AppendLine("-- =============================================================")
    [void]$out.AppendLine("DO $$")
    [void]$out.AppendLine("DECLARE")
    [void]$out.AppendLine("    v_ex_id  UUID;")
    [void]$out.AppendLine("    v_var_id UUID;")
    [void]$out.AppendLine("    v_id     UUID;")
    [void]$out.AppendLine("BEGIN")
    [void]$out.AppendLine("    IF EXISTS (SELECT 1 FROM exercises.exercise WHERE name = '$(Esc $en)') THEN")
    [void]$out.AppendLine("        RAISE NOTICE 'Already exists: $(Esc $en)'; RETURN;")
    [void]$out.AppendLine("    END IF;")
    [void]$out.AppendLine("    v_ex_id := gen_random_uuid();")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("    INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)")
    [void]$out.AppendLine("    VALUES (")
    [void]$out.AppendLine("        v_ex_id, '$(Esc $en)', '$difficulty', '$mechanics', '$force',")
    [void]$out.AppendLine("        $($uni.ToString().ToLowerInvariant()), $($bw.ToString().ToLowerInvariant()), '$risk', $($spot.ToString().ToLowerInvariant()), NULL, 'public', 'active',")
    [void]$out.AppendLine("        jsonb_build_object(")
    [void]$out.AppendLine("            'it', jsonb_build_object('name','$(Esc $it)','description','$itDesc'),")
    [void]$out.AppendLine("            'en', jsonb_build_object('name','$(Esc $en)','description','$enDesc')")
    [void]$out.AppendLine("        ),")
    [void]$out.AppendLine("        NOW(), NOW()")
    [void]$out.AppendLine("    );")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("    -- MUSCLES")
    $pP = @(75,70,65,60)
    for ($i=0; $i -lt [Math]::Min($pm.Count,4); $i++) {
        [void]$out.AppendLine("    SELECT id INTO v_id FROM exercises.muscle WHERE code='$($pm[$i])'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'primary',$($pP[$i]),NOW()) ON CONFLICT DO NOTHING; END IF;")
    }
    $pS = @(55,45,35)
    for ($i=0; $i -lt [Math]::Min($sm.Count,3); $i++) {
        [void]$out.AppendLine("    SELECT id INTO v_id FROM exercises.muscle WHERE code='$($sm[$i])'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_ex_id,v_id,'secondary',$($pS[$i]),NOW()) ON CONFLICT DO NOTHING; END IF;")
    }
    [void]$out.AppendLine("")
    [void]$out.AppendLine("    -- CATEGORIES")
    [void]$out.AppendLine("    SELECT id INTO v_id FROM exercises.category WHERE code='$category'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_ex_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;")
    [void]$out.AppendLine("")
    [void]$out.AppendLine("    -- EQUIPMENT")
    for ($i=0; $i -lt $equip.Count; $i++) {
        $isP = if ($i -eq 0) { "true" } else { "false" }
        [void]$out.AppendLine("    SELECT id INTO v_id FROM exercises.equipment WHERE code='$($equip[$i])'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_ex_id,v_id,true,$isP,1,NOW()) ON CONFLICT DO NOTHING; END IF;")
    }
    [void]$out.AppendLine("")
    [void]$out.AppendLine("    -- TAGS")
    [void]$out.AppendLine("    FOR v_id IN SELECT id FROM exercises.tag WHERE code IN($tagList) LOOP INSERT INTO exercises.exercise_tag VALUES(v_ex_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;")
    [void]$out.AppendLine("")

    if ($vars.Count -gt 0) {
        [void]$out.AppendLine("    -- VARIANTS")
        $base = DiffLevel $difficulty
        foreach ($v in $vars) {
            $vEn = [string]$v.en
            $vIt = [string]$v.it
            $vDiff = [string]$v.diff
            $vSpot = [bool]$v.spot

            $vUni = $uni -or (UnilateralByName $vEn)
            $vEquip = @($equip)
            if ($vEn -match "(?i)dumbbell") { $vEquip = @("dumbbell") }
            elseif ($vEn -match "(?i)kettlebell") { $vEquip = @("kettlebell") }
            elseif ($vEn -match "(?i)barbell") { $vEquip = @("barbell") }
            elseif ($vEn -match "(?i)band") { $vEquip = @("resistance_band") }
            elseif ($vEn -match "(?i)wall ball") { $vEquip = @("wall_ball") }
            if ($bw -and $vEquip -notcontains "none_bodyweight" -and $vEn -match "(?i)wall|floor") { $vEquip += "none_bodyweight" }
            if ($bw -and $vEquip.Count -eq 0) { $vEquip = @("none_bodyweight") }

            $vTagList = (Tags $category $vEn $mechanics $force $vUni $bw $vEquip $risk $vSpot $vDiff | ForEach-Object { "'$_'" }) -join ","
            $delta = (DiffLevel $vDiff) - $base
            if ($delta -gt 3) { $delta = 3 }; if ($delta -lt -3) { $delta = -3 }
            $vEnDesc = Esc ("Variation of $en. " + (DescEN $vEn))
            $vItDesc = Esc ("Variante di $it. " + (DescIT $vEn))

            [void]$out.AppendLine("    -- $vEn")
            [void]$out.AppendLine("    IF NOT EXISTS (SELECT 1 FROM exercises.exercise WHERE name='$(Esc $vEn)') THEN")
            [void]$out.AppendLine("        v_var_id := gen_random_uuid();")
            [void]$out.AppendLine("        INSERT INTO exercises.exercise (id,name,difficulty,mechanics,force,unilateral,bodyweight,overall_risk,spotter_required,owner_user_id,visibility,status,translations,created_at,updated_at)")
            [void]$out.AppendLine("        VALUES(v_var_id,'$(Esc $vEn)','$vDiff','$mechanics','$force',$($vUni.ToString().ToLowerInvariant()),$($bw.ToString().ToLowerInvariant()),'$risk',$($vSpot.ToString().ToLowerInvariant()),NULL,'public','active',")
            [void]$out.AppendLine("            jsonb_build_object('it',jsonb_build_object('name','$(Esc $vIt)','description','$vItDesc'),'en',jsonb_build_object('name','$(Esc $vEn)','description','$vEnDesc')),NOW(),NOW());")
            foreach ($mc in ($pm | Select-Object -First 2)) {
                [void]$out.AppendLine("        SELECT id INTO v_id FROM exercises.muscle WHERE code='$mc'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'primary',70,NOW()) ON CONFLICT DO NOTHING; END IF;")
            }
            foreach ($mc in ($sm | Select-Object -First 2)) {
                [void]$out.AppendLine("        SELECT id INTO v_id FROM exercises.muscle WHERE code='$mc'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_muscle VALUES(v_var_id,v_id,'secondary',45,NOW()) ON CONFLICT DO NOTHING; END IF;")
            }
            [void]$out.AppendLine("        SELECT id INTO v_id FROM exercises.category WHERE code='$category'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_category VALUES(v_var_id,v_id,true,NOW()) ON CONFLICT DO NOTHING; END IF;")
            for ($i=0; $i -lt $vEquip.Count; $i++) {
                $isP = if ($i -eq 0) { "true" } else { "false" }
                [void]$out.AppendLine("        SELECT id INTO v_id FROM exercises.equipment WHERE code='$($vEquip[$i])'; IF v_id IS NOT NULL THEN INSERT INTO exercises.exercise_equipment VALUES(v_var_id,v_id,true,$isP,1,NOW()) ON CONFLICT DO NOTHING; END IF;")
            }
            [void]$out.AppendLine("        FOR v_id IN SELECT id FROM exercises.tag WHERE code IN($vTagList) LOOP INSERT INTO exercises.exercise_tag VALUES(v_var_id,v_id,NOW()) ON CONFLICT DO NOTHING; END LOOP;")
            [void]$out.AppendLine("        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,$delta,NOW()) ON CONFLICT DO NOTHING;")
            [void]$out.AppendLine("    ELSE")
            [void]$out.AppendLine("        SELECT id INTO v_var_id FROM exercises.exercise WHERE name='$(Esc $vEn)';")
            [void]$out.AppendLine("        INSERT INTO exercises.exercise_variation VALUES(v_ex_id,v_var_id,$delta,NOW()) ON CONFLICT DO NOTHING;")
            [void]$out.AppendLine("    END IF;")
            [void]$out.AppendLine("")
        }
    }

    [void]$out.AppendLine("END $$;")
    return $out.ToString()
}

$repoRoot = (Resolve-Path ".").Path
$donePath = Join-Path $repoRoot "sql\\_done\\done_registry.md"
$outDir = Join-Path $repoRoot "sql\\exercises"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function DoneSet {
    $set = @{}
    if (Test-Path $donePath) {
        foreach ($l in (Get-Content $donePath)) {
            if ($l -match "^\|\s*([^|]+)\s*\|") {
                $n = $Matches[1].Trim()
                if ($n -ne "" -and $n -ne "Exercise Name (EN)") { $set[$n] = 1 }
            }
        }
    }
    return $set
}

function SeededSet {
    $set = @{}
    Get-ChildItem $outDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        $c = Get-Content -Raw $_.FullName
        foreach ($m in [regex]::Matches($c, "VALUES\s*\(\s*v_(?:ex|var)_id\s*,\s*'([^']+)'")) {
            $set[$m.Groups[1].Value] = 1
        }
    }
    return $set
}

$alias = @{
    "Bench Press" = "Barbell Bench Press"
    "Back Squat"  = "Barbell Back Squat"
    "Barbell Row" = "Barbell Bent-Over Row"
}

$seeded = SeededSet
$agent = "agent_Epicurus"
$created = 0
$skipped = 0

function Append-DoneLine([string]$line) {
    for ($i = 0; $i -lt 200; $i++) {
        try {
            Add-Content -Path $donePath -Value $line -Encoding utf8 -ErrorAction Stop
            return
        } catch {
            Start-Sleep -Milliseconds 200
        }
    }
    throw "Could not append to done_registry.md after retries (file locked): $donePath"
}

Get-ChildItem crossfit,functional_training -Recurse -File -Filter *.md | ForEach-Object {
    $category = $_.Directory.Name
    $content = Get-Content -Raw $_.FullName
    foreach ($m in [regex]::Matches($content, "(?ms)^##\s+([^\r\n]+)\r?\n(.*?)(?=^##\s+|\z)")) {
        $en = $m.Groups[1].Value.Trim()
        $blk = $m.Groups[2].Value
        if ([string]::IsNullOrWhiteSpace($en)) { continue }

        $done = DoneSet
        if ($done.ContainsKey($en)) { $skipped++; continue }
        if ($seeded.ContainsKey($en)) { $skipped++; continue }
        if ($alias.ContainsKey($en) -and $seeded.ContainsKey($alias[$en])) { $skipped++; continue }

        $it = ([regex]::Match($blk, "(?m)^- \\*\\*IT\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($it)) { $it = $en }

        $difficulty = ([regex]::Match($blk, "(?m)^- \\*\\*Difficulty\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant()
        $mechanics = ([regex]::Match($blk, "(?m)^- \\*\\*Mechanics\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant()
        $force = ([regex]::Match($blk, "(?m)^- \\*\\*Force\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant()
        $uni = ([regex]::Match($blk, "(?m)^- \\*\\*Unilateral\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant() -eq "true"
        $bw = ([regex]::Match($blk, "(?m)^- \\*\\*Bodyweight\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant() -eq "true"
        $risk = ([regex]::Match($blk, "(?m)^- \\*\\*Risk\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant()
        $spot = ([regex]::Match($blk, "(?m)^- \\*\\*Spotter\\*\\*:\\s*(.+)$")).Groups[1].Value.Trim().ToLowerInvariant() -eq "true"

        if ([string]::IsNullOrWhiteSpace($difficulty)) { $difficulty = "intermediate" }
        if ([string]::IsNullOrWhiteSpace($mechanics)) { $mechanics = "compound" }
        if ([string]::IsNullOrWhiteSpace($force)) { $force = "dynamic" }
        if ([string]::IsNullOrWhiteSpace($risk)) { $risk = "medium" }

        $pmRaw = ([regex]::Match($blk, "(?m)^- \\*\\*Primary Muscles\\*\\*:\\s*(.+)$")).Groups[1].Value
        $smRaw = ([regex]::Match($blk, "(?m)^- \\*\\*Secondary Muscles\\*\\*:\\s*(.+)$")).Groups[1].Value
        $pm = @()
        foreach ($t in ($pmRaw -split ",")) { $c = MuscleCode $t; if ($c -and $pm -notcontains $c) { $pm += $c } }
        $sm = @()
        foreach ($t in ($smRaw -split ",")) { $c = MuscleCode $t; if ($c -and $pm -notcontains $c -and $sm -notcontains $c) { $sm += $c } }
        if ($pm.Count -eq 0 -and $sm.Count -gt 0) { $pm = @($sm[0]); $sm = $sm | Select-Object -Skip 1 }
        if ($pm.Count -eq 0) { $pm = @("rectus_abdominis") }

        $eqRaw = ([regex]::Match($blk, "(?m)^- \\*\\*Equipment\\*\\*:\\s*(.+)$")).Groups[1].Value
        $equip = @()
        foreach ($t in ($eqRaw -split ",")) { $c = EquipCode $t $bw; if ($c -and $equip -notcontains $c) { $equip += $c } }
        if ($equip.Count -eq 0 -and $bw) { $equip = @("none_bodyweight") }

        $vars = @()
        $vm = [regex]::Match($blk, "(?ms)^\*\*Variants:\*\*\s*\r?\n(?<v>(?:- .*(?:\r?\n|$))+)")
        if ($vm.Success) {
            foreach ($ln in ($vm.Groups["v"].Value -split "\r?\n" | Where-Object { $_ -match "^- " })) {
                $line = ($ln -replace "^-\s*", "").Trim()
                $p = $line -split "\s*\|\s*"
                if ($p.Count -lt 4) { continue }
                $vEn = $p[0].Trim()
                $vIt = $p[1].Trim()
                $vDiff = ($p[2] -replace "^diff:\\s*", "").Trim().ToLowerInvariant()
                $vSpot = (($p[3] -replace "^spot:\\s*", "").Trim().ToLowerInvariant() -eq "true")
                $vars += [pscustomobject]@{ en=$vEn; it=$vIt; diff=$vDiff; spot=$vSpot }
            }
        }

        $file = (Snake $en) + ".sql"
        $path = Join-Path $outDir $file
        if (Test-Path $path) { $skipped++; continue }

        $sql = BuildSql $category $en $it $difficulty $mechanics $force $uni $bw $risk $spot $pm $sm $equip $vars
        Set-Content -Path $path -Value $sql -Encoding utf8
        Append-DoneLine ("| {0} | {1} | {2} | {3} |" -f $en, $file, $vars.Count, $agent)

        $seeded[$en] = 1
        $created++
    }
}

"Created: $created"
"Skipped: $skipped"
