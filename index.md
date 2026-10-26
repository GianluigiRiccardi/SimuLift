---
layout: null
title: SimuLift
---
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SimuLift. Check a lift before you make it</title>
<meta name="description" content="SimuLift is a Simulink model that checks a lifting operation before it is executed: impact force, crane overload and wind force, with an Excel input template and a 2D animation.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@100..125,400..800&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&display=swap" rel="stylesheet">
<style>
:root{--petrol:#0F2D4A;--paper:#EEF1F3;--ink:#14202B;--steel:#5B6B78;--rule:#C9D1D8;--amber:#D9930F;--bg:#FAFBFC}
@media (prefers-color-scheme: dark){:root{--petrol:#9CC3E6;--paper:#16232F;--ink:#E6ECF1;--steel:#9AA9B5;--rule:#2C3B48;--amber:#F0B23A;--bg:#0E1821}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:400 1.125rem/1.7 "Source Serif 4",Georgia,serif}
a{color:var(--petrol);text-underline-offset:3px}
a:focus-visible{outline:3px solid var(--amber);outline-offset:3px}
.wrap{max-width:46rem;margin:0 auto;padding:0 1.25rem}
header{background:var(--paper);border-bottom:1px solid var(--rule)}
header .wrap{padding:4.5rem 1.25rem 3rem}
h1,h2,h3,.tag,.btn,.check b,.steps li::marker{font-family:Archivo,system-ui,sans-serif}
h1{font-size:clamp(2.8rem,8vw,4.6rem);line-height:1;font-weight:750;font-stretch:112%;letter-spacing:-.02em;margin:0;color:var(--petrol)}
.tag{font-stretch:125%;font-weight:500;font-size:clamp(1.1rem,2.8vw,1.4rem);margin:.9rem 0 2rem}
.btn{display:inline-block;font-weight:600;font-size:1rem;padding:.75rem 1.3rem;text-decoration:none;border-radius:2px;margin:0 .5rem .5rem 0}
.btn.primary{background:var(--petrol);color:var(--bg)}
.btn.secondary{border:2px solid var(--petrol);color:var(--petrol)}
main .wrap{padding-top:3rem;padding-bottom:4rem}
.lead{font-family:Archivo,sans-serif;font-size:1.35rem;line-height:1.45;font-weight:500;margin:0 0 1.5rem}
h2{font-size:1.5rem;font-weight:700;font-stretch:110%;color:var(--petrol);margin:3.5rem 0 1.25rem;padding-top:.5rem;border-top:3px solid var(--petrol);display:inline-block}
.check{border-left:3px solid var(--rule);padding:.2rem 0 .2rem 1.1rem;margin:0 0 1.6rem}
.check b{display:block;font-size:1.15rem;color:var(--ink)}
.check p{margin:.2rem 0 0}
.formula{font-family:Archivo,sans-serif;font-stretch:105%;font-weight:600;color:var(--petrol);background:var(--paper);padding:.15rem .45rem;border-radius:2px;white-space:nowrap}
.steps{padding-left:1.4rem;margin:0}
.steps li{margin:0 0 .9rem;padding-left:.3rem}
.steps li::marker{color:var(--petrol);font-weight:700}
code{font-size:.9em;background:var(--paper);padding:.05rem .3rem;border-radius:2px}
.note{border:1px solid var(--rule);border-left:4px solid var(--amber);padding:1rem 1.2rem;background:var(--paper);margin:1.5rem 0}
.note p{margin:0}
footer{border-top:1px solid var(--rule);background:var(--paper)}
footer .wrap{padding:2.5rem 1.25rem 3rem;font-size:1rem;color:var(--steel)}
</style>
</head>
<body>
<header>
  <div class="wrap">
    <h1>SimuLift</h1>
    <p class="tag">Check a lift before you make it</p>
    <a class="btn primary" href="https://github.com/GianluigiRiccardi/SimuLift/raw/main/SimuLift_v1_2_WithLamps.slx">Download the model (v1.2)</a>
    <a class="btn secondary" href="https://github.com/GianluigiRiccardi/SimuLift">View the code on GitHub</a>
  </div>
</header>
<main>
  <div class="wrap">
    <p class="lead">SimuLift is a Simulink model that runs three physics checks on a planned lift and returns a verdict before anyone hooks the load.</p>
    <p>It was built for safety-critical industrial sites, where a lift is approved on paper and executed in conditions that can drift from the plan: a heavier rigging set, a stronger wind, a load that could drop further than expected. SimuLift makes those three variables explicit and shows, check by check, which one would stop the lift.</p>

    <h2>What it checks</h2>
    <div class="check"><b>Impact</b><p>The force of a dropped load, from the energy released over the deformation distance: <span class="formula">F = m·g·h / δ</span>, compared with an admissible threshold.</p></div>
    <div class="check"><b>Overload</b><p>Total suspended mass (load, hook block and slings) times the safety factor, compared with the crane capacity at the working radius: <span class="formula">m·SF ≤ capacity</span>.</p></div>
    <div class="check"><b>Wind</b><p>Wind speed from the Beaufort scale and drag on the exposed area: <span class="formula">F = ½·ρ·C<sub>d</sub>·A·v²</span>, compared with an admissible force.</p></div>

    <h2>How to use it</h2>
    <ol class="steps">
      <li>Fill in the lift data in <code>SimuLift_Dati_Sollevamento.xlsx</code>: load, hook block, slings, safety factor, drop height, deformation, Beaufort force, exposed area and crane capacity.</li>
      <li>Run <code>simulift_import_excel</code> to write the values into the model.</li>
      <li>Open <code>SimuLift_v1_2_WithLamps.slx</code> and run it: one lamp per check and a final lamp give the verdict.</li>
      <li>Run <code>simulift_animate_2d</code> for a 2D scene of the lift computed from the same data.</li>
    </ol>

    <h2>What's new in v1.2</h2>
    <p>Status lamps for each check and for the global verdict, a single Excel template as input, an import script that writes it into the model, and a 2D animation driven by the same formulas and thresholds. The v1.0 model and the v1.1 automation scripts remain available in the repository.</p>

    <div class="note"><p>The impact check models a full drop of the load and is deliberately conservative: with the template values the verdict is LIFT DENIED by design. SimuLift is a demonstration and research tool. It does not replace a lift plan, the crane load charts, a competent person's assessment or the applicable standards.</p></div>

    <h2>Next</h2>
    <p>A dynamic model in Simscape Multibody, where load swing, sling tension and loss of grip emerge from the physics instead of being checked as static limits.</p>
  </div>
</main>
<footer>
  <div class="wrap">Built in MATLAB and Simulink by <a href="https://gianluigiriccardi.github.io">Gianluigi Riccardi</a>. Released under the MIT License.</div>
</footer>
</body>
</html>
