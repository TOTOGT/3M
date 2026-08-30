/-
  LogisticRadial.lean — the radial law of LAW3M, and where the sigmoid comes from.

  law3m.html calls the radial term `r * (1 - r^2)` a "logistic contraction".
  That sentence is true in a stronger sense than the word usually carries, and
  this file is the sentence checked rather than asserted.

    · `sq_is_logistic`            the SQUARED radius obeys the logistic equation
                                  exactly: with u = r^2 and ṙ = r(1 - r^2),
                                  u̇ = 2u(1 - u).

    · `mu_max_eq_neg_two`         linearising the radial field at the limit cycle
                                  r = 1 gives exactly -2 — the transverse Lyapunov
                                  exponent μ_max of the invariant triple
                                  (T*, μ, τ) = (2π, -2, 2).

    · `sigmoid2_solves_logistic`  t ↦ 1 / (1 + exp (-2t)) solves u̇ = 2u(1 - u).
                                  This is the logistic curve of a neuron,
                                  a = 1 / (1 + e^(-z)), appearing here as the TIME
                                  COURSE of the approach to the limit cycle, with
                                  z = 2t.

  WHAT THIS FILE DOES NOT ESTABLISH, stated here so no page can quote it for more.

    · The -2 is forced by the cubic normal form. Any system reduced to that form
      yields -2. It is a structural consequence, not an independent measurement,
      and it is not evidence for the physical reading of LAW3M.

    · The sigmoid appears here as a TRAJECTORY, not as an operator. σ is a
      diffeomorphism onto (0,1) — strictly monotone, invertible, information
      preserving. It is NOT a Whitney fold, and nothing below licenses calling
      it one. Irreversibility in a network enters at the threshold or the argmax,
      not at σ.

    · Nothing here says the debris of a ring, or any physical system, obeys this
      equation. It says what this equation does.

  STATUS. Compiled against Mathlib (lean4 v4.33.1) on 2026-08-29. Every theorem
  below was probed with `#print axioms` and reports exactly

      [propext, Classical.choice, Quot.sound]

  no `sorryAx`, no `native_decide`. Tier 1 by the registry definition. Regenerate
  with `lake env lean LogisticRadial.lean` in any project that requires Mathlib.
-/
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic

open Real

namespace LAW3M

/-- The radial field of the LAW3M / dm³ attractor: `ṙ = r (1 - r²)`. -/
noncomputable def radial (r : ℝ) : ℝ := r * (1 - r ^ 2)

/-- `radial` in expanded form. -/
theorem radial_eq (r : ℝ) : radial r = r - r ^ 3 := by
  unfold radial; ring

/-! ### 1. The squared radius is exactly logistic -/

/-- If `r` solves the radial equation `ṙ = r(1 - r²)`, then `u = r²` solves the
logistic equation `u̇ = 2u(1 - u)`. This is the precise content of calling
`r(1 - r²)` a *logistic* contraction: it is the logistic equation in `r²`. -/
theorem sq_is_logistic (r : ℝ → ℝ) (t : ℝ)
    (hr : HasDerivAt r (radial (r t)) t) :
    HasDerivAt (fun s => r s ^ 2) (2 * (r t ^ 2) * (1 - r t ^ 2)) t := by
  rw [radial] at hr
  have hp : HasDerivAt (fun x : ℝ => x ^ 2) (2 * r t) (r t) := by
    simpa using hasDerivAt_pow 2 (r t)
  exact (hp.comp t hr).congr_deriv (by ring)

/-! ### 2. The transverse exponent at the limit cycle -/

/-- The derivative of the radial field. -/
theorem hasDerivAt_radial (r : ℝ) : HasDerivAt radial (1 - 3 * r ^ 2) r := by
  have h1 : HasDerivAt (fun x : ℝ => x) 1 r := hasDerivAt_id r
  have h2 : HasDerivAt (fun x : ℝ => x ^ 3) (3 * r ^ 2) r := by
    simpa using hasDerivAt_pow 3 r
  have h : HasDerivAt (fun x : ℝ => x - x ^ 3) (1 - 3 * r ^ 2) r := h1.sub h2
  have e : radial = fun x : ℝ => x - x ^ 3 := by
    funext x; exact radial_eq x
  rw [e]; exact h

/-- **μ_max = -2.** Linearising the radial field at the limit cycle `r = 1`
gives exactly `-2`: the transverse Lyapunov exponent of the invariant triple. -/
theorem mu_max_eq_neg_two : HasDerivAt radial (-2 : ℝ) 1 := by
  have h := hasDerivAt_radial 1
  have e : (1 : ℝ) - 3 * (1 : ℝ) ^ 2 = -2 := by norm_num
  rwa [e] at h

/-- The limit cycle is a zero of the radial field: `r = 1` is stationary. -/
theorem radial_one : radial 1 = 0 := by
  unfold radial; norm_num

/-! ### 3. The sigmoid is the trajectory -/

/-- The logistic curve with rate `2` — the neuron's `a = 1 / (1 + e^(-z))`
at `z = 2t`. -/
noncomputable def sigmoid2 (t : ℝ) : ℝ := (1 + exp (-(2 * t)))⁻¹

theorem sigmoid2_pos (t : ℝ) : (0 : ℝ) < 1 + exp (-(2 * t)) := by positivity

/-- **The sigmoid solves the logistic equation.** So the approach of the radius
to the limit cycle is, in `u = r²`, a logistic curve in time — the same function
a sigmoid unit computes, with `z = 2t`. -/
theorem sigmoid2_solves_logistic (t : ℝ) :
    HasDerivAt sigmoid2 (2 * sigmoid2 t * (1 - sigmoid2 t)) t := by
  have hne : (1 + exp (-(2 * t))) ≠ 0 := ne_of_gt (sigmoid2_pos t)
  have hlin : HasDerivAt (fun s : ℝ => -(2 * s)) (-2 : ℝ) t := by
    simpa using (hasDerivAt_id t).const_mul (-2 : ℝ) |>.congr_deriv (by ring)
  have hexp : HasDerivAt (fun s : ℝ => exp (-(2 * s))) (exp (-(2 * t)) * (-2)) t :=
    hlin.exp
  have hden : HasDerivAt (fun s : ℝ => 1 + exp (-(2 * s)))
      (exp (-(2 * t)) * (-2)) t := hexp.const_add 1
  have hinv := hden.inv hne
  have key : -(exp (-(2 * t)) * (-2)) / (1 + exp (-(2 * t))) ^ 2
      = 2 * sigmoid2 t * (1 - sigmoid2 t) := by
    unfold sigmoid2
    field_simp
    ring
  rw [← key]
  exact hinv

/-- The sigmoid takes values strictly in `(0, 1)` — it is a squash, never
saturating exactly. Recorded because it is the reason σ is *not* a fold:
it is injective and its image misses both endpoints. -/
theorem sigmoid2_mem_Ioo (t : ℝ) : sigmoid2 t ∈ Set.Ioo (0 : ℝ) 1 := by
  constructor
  · exact inv_pos.mpr (sigmoid2_pos t)
  · rw [sigmoid2, inv_lt_one_iff₀]
    right
    nlinarith [exp_pos (-(2 * t))]



/-! ### 4. The neuron: the collapse is in the sum, not in the squash -/

namespace Neuron

/-- The logistic unit `a = 1 / (1 + e^(-z))`. -/
noncomputable def sigmoid (z : ℝ) : ℝ := (1 + exp (-z))⁻¹

theorem sigmoid_denom_pos (z : ℝ) : (0 : ℝ) < 1 + exp (-z) := by positivity

/-- `z = Σᵢ wᵢ xᵢ + b`, the affine part. -/
noncomputable def preact {n : ℕ} (w : Fin n → ℝ) (b : ℝ) (x : Fin n → ℝ) : ℝ :=
  (∑ i, w i * x i) + b

/-- A single unit: `ŷ = a = σ(z)`. -/
noncomputable def unit {n : ℕ} (w : Fin n → ℝ) (b : ℝ) (x : Fin n → ℝ) : ℝ :=
  sigmoid (preact w b x)

/-- σ is strictly increasing. -/
theorem sigmoid_strictMono : StrictMono sigmoid := by
  intro a b hab
  have h : exp (-b) < exp (-a) := exp_lt_exp.mpr (by linarith)
  have hb : (0 : ℝ) < 1 + exp (-b) := sigmoid_denom_pos b
  unfold sigmoid
  have hb' : (0 : ℝ) < 1 + exp (-b) := hb
  gcongr

/-- **σ is injective.** Nothing is lost at the nonlinearity: it is a bijection
onto its image and can be run backwards exactly. This is why σ is NOT a Whitney
fold — a fold is two-to-one at its critical point, and σ has none. -/
theorem sigmoid_injective : Function.Injective sigmoid :=
  sigmoid_strictMono.injective

/-- σ never reaches 0 or 1. -/
theorem sigmoid_mem_Ioo (z : ℝ) : sigmoid z ∈ Set.Ioo (0 : ℝ) 1 := by
  constructor
  · exact inv_pos.mpr (sigmoid_denom_pos z)
  · rw [sigmoid, inv_lt_one_iff₀]
    right
    nlinarith [exp_pos (-z)]

/-- **The unit is blind along the kernel of `w`.** Move the input by any `d` with
`⟪w, d⟫ = 0` and the output is unchanged. This is where a neuron actually
forgets: the affine sum collapses `n` dimensions to one. The irreversibility of
a layer lives in the compression, not in the squash. -/
theorem unit_invariant_on_kernel {n : ℕ} (w : Fin n → ℝ) (b : ℝ)
    (x d : Fin n → ℝ) (hd : (∑ i, w i * d i) = 0) :
    unit w b (fun i => x i + d i) = unit w b x := by
  unfold unit preact
  congr 2
  have : (∑ i, w i * (x i + d i)) = (∑ i, w i * x i) + (∑ i, w i * d i) := by
    rw [← Finset.sum_add_distrib]
    exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [this, hd, add_zero]

end Neuron

end LAW3M
