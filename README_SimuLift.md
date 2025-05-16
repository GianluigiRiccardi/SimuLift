
# SimuLift

**SimuLift** is a Simulink-based predictive safety model for lifting operations.  
It evaluates overload conditions, wind force, and impact risks using real-world physics formulas, returning a clear visual verdict: **“Safe to Lift”** or **“Lift Denied”**.

---

## 🚀 Introduction

Heavy lifting operations, especially with cranes, involve significant safety risks — from overloading the equipment to unexpected gusts of wind or impact due to drops.  
**SimuLift** was created to simulate these scenarios and support engineers, maintenance planners, and students in designing safer procedures.  
It’s ideal for:
- Safety-focused engineers
- Industrial maintenance teams
- Engineering students learning predictive simulation

---

## 🧰 How It Works

SimuLift is structured in 3 main analysis blocks:

1. **Impact Force Analysis**  
   Calculates force based on mass, height, and deformation margin.
2. **Overload Check**  
   Verifies total mass (payload + pulley + slings) against crane capacity with safety factor.
3. **Wind Force Evaluation**  
   Uses Beaufort scale to compute wind speed and resulting force on exposed area.

Each force is compared against thresholds.  
Display blocks indicate if the condition is **safe**, **borderline**, or **dangerous**.

---

## 🖥️ Example Simulation

Imagine a scenario where a 150 kg load must be lifted during windy conditions.

- Beaufort scale: 6 (Strong breeze)
- Deformation limit: 0.2 m
- Safety factor: 1.25

Modify the constant blocks in the Simulink model accordingly.  
Run the simulation and observe the verdict:
- Green: Safe to lift
- Red: One or more conditions violated

> See `docs/LiftPlan_diagram.png` for a full visual overview.

---

## 🔧 Modifiable Parameters

You can safely change:

| Parameter               | Block Name            | Effect                         |
|------------------------|-----------------------|--------------------------------|
| Mass of slings         | `Slings_Weight`       | Affects total weight           |
| Mass of pulley         | `Pulley_Weight`       | Affects total weight           |
| Payload (load)         | `Theoretical_Weight`  | Affects total weight           |
| Safety factor          | `Safety_Factor`       | Changes overload calculation   |
| Drop height            | `Height`              | Affects impact force           |
| Deformation margin     | `Deformation_Limit`   | Influences impact severity     |
| Beaufort scale         | `Beaufort_Scale`      | Determines wind speed          |
| Exposed area           | `Exposed_Area`        | Used in wind force calculation |

---

## 📤 Output Signals

| Display Block          | Meaning                            |
|------------------------|-------------------------------------|
| `Impact_Status_Display` | Safe or dangerous impact force     |
| `Overload_Status_Display` | OK load or overload risk          |
| `Wind_Status_Display`   | Wind within or beyond safe limit   |
| `FinalVerdict_Display`  | Overall decision to proceed or not |

---

## 🧱 Requirements

- MATLAB R2024a or newer
- Simulink
- No additional toolbox required

---

## 📦 Installation

1. Clone or download the repository  
2. Open `SimuLift.slx` in MATLAB Simulink  
3. Modify constants as needed  
4. Run the simulation and observe safety indicators

---

## 📚 Resources

- [MathWorks: Simulink documentation](https://www.mathworks.com/help/simulink/)
- [Beaufort wind scale](https://en.wikipedia.org/wiki/Beaufort_scale)
- [Crane lifting standards (OSHA)](https://www.osha.gov/cranes-derricks)

---

## 🔄 Changelog

**v1.0 (May 2025)**  
- Initial release: complete model, 4 visual indicators, README

---

## 🇮🇹 Versione italiana disponibile presto!

---

## 🛡️ License

MIT License – free to use and adapt.
