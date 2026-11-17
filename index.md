---
layout: null
title: SimuLift
---
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SimuLift. The hook goes up only after the signature</title>
<meta name="description" content="SimuLift is a MATLAB app for planning a mobile crane lift: load check, lift classification, contingency plan over plant in service, layout on a site plan, two-point rigging plan and a Load Plan in PDF.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@100..125,400..800&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600&display=swap" rel="stylesheet">
<style>
:root{--petrol:#0F2D4A;--paper:#EEF1F3;--ink:#14202B;--steel:#5B6B78;--rule:#C9D1D8;--amber:#D9930F;--bg:#FAFBFC;--go:#1A7F3C;--stop:#B3261E}
@media (prefers-color-scheme: dark){:root{--petrol:#9CC3E6;--paper:#16232F;--ink:#E6ECF1;--steel:#9AA9B5;--rule:#2C3B48;--amber:#F0B23A;--bg:#0E1821;--go:#5CC27E;--stop:#F08A80}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:400 1.125rem/1.7 "Source Serif 4",Georgia,serif}
a{color:var(--petrol);text-underline-offset:3px}
a:focus-visible{outline:3px solid var(--amber);outline-offset:3px}
.wrap{max-width:46rem;margin:0 auto;padding:0 1.25rem}
header{background:var(--paper);border-bottom:1px solid var(--rule)}
header .wrap{padding:4.5rem 1.25rem 3rem}
h1,h2,h3,.tag,.btn,.check b,.steps li::marker,.verdict{font-family:Archivo,system-ui,sans-serif}
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
pre{background:var(--paper);border:1px solid var(--rule);padding:.9rem 1rem;overflow-x:auto;font-size:.95rem;line-height:1.5;margin:0 0 1.2rem}
pre code{background:none;padding:0}
.model{margin:2rem -1.25rem 0;}
.model img{display:block;width:100%;height:auto;border:1px solid var(--rule);background:#fff}
.model figcaption{font-size:.95rem;color:var(--steel);margin:.6rem 1.25rem 0}
@media (min-width:900px){.model{margin:2.5rem -8rem 0}.model figcaption{margin-left:8rem;margin-right:8rem}}
.verdict{display:block;font-weight:700;font-stretch:110%;font-size:1rem;letter-spacing:.02em}
.verdict.go{color:var(--go)}.verdict.amber{color:var(--amber)}.verdict.stop{color:var(--stop)}
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
    <p class="tag">The hook goes up only after the signature</p>
    <a class="btn primary" href="https://github.com/GianluigiRiccardi/SimuLift/archive/refs/heads/main.zip">Download everything (ZIP)</a>
    <a class="btn secondary" href="docs/Piano_di_Carico_esempio.pdf">Sample Load Plan (PDF)</a>
    <a class="btn secondary" href="https://github.com/GianluigiRiccardi/SimuLift">View the code on GitHub</a>
  </div>
</header>
<main>
  <div class="wrap">
    <p class="lead">SimuLift 2.0 is a MATLAB app that prepares the decisions behind a mobile crane lift and writes them into a Load Plan you can sign.</p>
    <p>The capacity check is the easy part of a lift plan. What decides the outcome is what is often left implicit: which class the lift falls into, who has to approve it, and what happens if the load drops onto a line in service. SimuLift makes those decisions explicit before anyone hooks the load, and puts them on paper with one button.</p>

    <figure class="model">
      <a href="docs/app_verifica.png"><img src="docs/app_verifica.png" alt="SimuLift app, Check tab: load data table, verdict LIFT WITH CONTINGENCY PLAN, mobile crane sketch with the boom to scale and utilisation against limits" width="1650" height="1000"></a>
      <figcaption>The Check tab. Example with fictitious data: a 1,200 kg pipe spool lifted over a diesel line in service.</figcaption>
    </figure>

    <h2>Three verdicts</h2>
    <div class="check"><span class="verdict stop">LIFT DENIED</span><p>The total lift exceeds the liftable capacity, or the forecast wind exceeds the crane's allowed in-service speed. The answer is no.</p></div>
    <div class="check"><span class="verdict amber">LIFT WITH CONTINGENCY PLAN</span><p>The numbers are fine, but the load travels over something that must not break: above 500 kg over plant in service or occupied buildings, or any load over power lines or plant holding toxic gas. The answer is yes, once the contingency actions are written and in place.</p></div>
    <div class="check"><span class="verdict go">SAFE TO LIFT</span><p>Every other case.</p></div>
    <p>Each lift is also classified as standard, non-standard or critical, with the reasons, so the plan states who must approve it.</p>

    <h2>What it computes</h2>
    <div class="check"><b>Load summary</b><p>Load, slings, hook block and a contingency applied to the load: <span class="formula">total = W + W<sub>slings</sub> + W<sub>block</sub> + c·W</span>, compared with the liftable capacity read from the manufacturer's load chart.</p></div>
    <div class="check"><b>Wind</b><p>The Beaufort force is converted to the upper speed of its class and compared with the crane's allowed in-service speed.</p></div>
    <div class="check"><b>Layout</b><p>On a site plan loaded as an image: the crane seen from above, the circle of the boom projection <span class="formula">d = L·cos α</span> and the lift point, with the measured distance compared with the projection.</p></div>
    <div class="check"><b>Rigging</b><p>Two pick points on a single hook. The centre of gravity settles under the hook, so an off-centre load tilts: <span class="formula">tan θ = e / h</span>. The app shows the tilt and the sling tensions, and proposes the pick points that keep the load level.</p></div>

    <figure class="model">
      <a href="docs/app_layout.png"><img src="docs/app_layout.png" alt="Layout tab: site plan with the crane seen from above, boom projection circle and lift point over a line in service" width="1650" height="1000"></a>
      <figcaption>The Layout tab: crane position, boom projection and lift point on a synthetic site plan.</figcaption>
    </figure>

    <figure class="model">
      <a href="docs/app_imbracatura.png"><img src="docs/app_imbracatura.png" alt="Rigging plan tab: a 1,000 kg load tilted by 15 degrees with tensions of 454 and 842 kg, and the same load level with 671 kg per sling after moving the pick points" width="1650" height="1000"></a>
      <figcaption>The Rigging plan tab. With the centre of gravity 0.6 m off centre the load tilts by 15° and one sling carries almost twice the other; moving the pick points levels it at 671 kg per sling.</figcaption>
    </figure>

    <h2>How to use it</h2>
    <pre><code>SimuLiftApp          % Italian interface
SimuLiftApp("en")    % English interface</code></pre>
    <ol class="steps">
      <li>In the Check tab, edit the Value column and press <b>Run simulation</b>.</li>
      <li>Say what lies under or near the load path, and whether more than one crane or special lifting gear is involved.</li>
      <li>Optionally, load the site plan and complete the rigging plan.</li>
      <li>Fill in the document data and press <b>Generate Load Plan (PDF)</b>.</li>
    </ol>
    <p>From the command line, for example on MATLAB Mobile: <code>SimuLift_Mobile(Load_kg=1200, Asset="diesel")</code>. Requires MATLAB R2026a, with no extra toolbox for the app and the PDF. 25 unit tests cover the load check, the classification and the rigging statics.</p>

    <div class="note"><p>SimuLift is a demonstration and research tool. It does not replace a lift plan written by a competent person, the crane manufacturer's load charts or the applicable regulations. It is a static check: no load dynamics. The rigging plan covers two pick points on a single hook. The Load Plan is generated in Italian, and its risk ratings, procedure and contingency actions are a generic starting point to be reviewed. All names, data and the site plan in the examples are fictitious.</p></div>

    <h2>Next</h2>
    <p>Capacity derived from a specific crane's load chart, four-point lifts and spreader beams, a Simscape Multibody model where load swing emerges from the physics, and field data from the hook and the anemometer. That is the path from a digital model towards a digital twin; SimuLift is not one yet.</p>
    <p>The v1.2 Simulink model with status lamps, the Excel template and the 2D animation remain in the repository.</p>
  </div>
</main>
<footer>
  <div class="wrap">Built in MATLAB by <a href="https://gianluigiriccardi.github.io">Gianluigi Riccardi</a>. Released under the MIT License.</div>
</footer>
</body>
</html>
