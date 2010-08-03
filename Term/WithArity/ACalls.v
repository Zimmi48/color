(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2004-12-22

symbols defined by a set of rules, list of calls in a rhs
*)

Set Implicit Arguments.

Require Import LogicUtil.
Require Import ATrs.
Require Import ListUtil.
Require Import VecUtil.
Require Import EqUtil.
Require Import BoolUtil.

Section S.

Variable Sig : Signature.

Notation term := (term Sig). Notation terms := (vector term).
Notation rule := (rule Sig). Notation rules := (list rule).

(***********************************************************************)
(** check whether [f] is defined by [l] *)

Fixpoint defined (f : Sig) (l : rules) {struct l} : bool :=
  match l with
    | nil => false
    | r :: l' =>
      match lhs r with
	| Var _ => defined f l'
	| Fun g ts => beq_symb f g || defined f l'
      end
  end.

Lemma lhs_fun_defined : forall (f : Sig) us r R,
  In (mkRule (Fun f us) r) R -> defined f R = true.

Proof.
induction R. auto. simpl. intro H. destruct H. subst a. simpl.
rewrite (beq_refl (@beq_symb_ok Sig)). auto. destruct a. simpl.
destruct lhs. auto. apply orb_intror. auto.
Qed.

Lemma defined_app : forall f l1 l2,
 defined f (l1 ++ l2) = defined f l1 || defined f l2.

Proof.
intros. induction l1; auto. simpl. destruct (lhs a); auto.
rewrite IHl1, orb_assoc; refl.
Qed.

Lemma defined_elim : forall f R,
 defined f R = true -> exists v, exists r, In (mkRule (Fun f v) r) R.

Proof.
intros. induction R. simpl in H. discriminate H.
simpl. simpl in H. destruct a as [a1 a2]. simpl in H. destruct a1.
destruct (IHR H) as [v H0]; destruct H0 as [r H0]. exists v; exists r; auto.
destruct (orb_prop _ _ H). Focus 2. destruct (IHR H0) as [v' H1].
destruct H1 as [r H1]. exists v'; exists r. auto.
rewrite beq_symb_ok in H0; rewrite H0. exists v; exists a2. left; refl.
Qed.

(***********************************************************************)
(** list of calls to a defined symbol in a term *)

Variable R : rules.

Fixpoint calls (t : term) : list term :=
  match t with
    | Var v => nil
    | Fun f ts =>
      let fix vcalls n (ts : terms n) {struct ts} : list term :=
        match ts with
          | Vnil => nil
          | Vcons u n' ts' => calls u ++ vcalls n' ts'
        end
      in match defined f R with
	   | true => t :: vcalls (arity f) ts
	   | false => vcalls (arity f) ts
	 end
  end.

Fixpoint vcalls n (ts : terms n) {struct ts} : list term :=
  match ts with
    | Vnil => nil
    | Vcons u _ ts' => calls u ++ vcalls ts'
  end.

Lemma calls_fun : forall f ts, calls (Fun f ts) =
  match defined f R with
    | true => Fun f ts :: vcalls ts
    | false => vcalls ts
  end.

Proof.
intros. reflexivity.
Qed.

Definition undefined t :=
  match t with
  | Fun f _ => negb (defined f R)
  | _ => false
  end.

Definition undefined_lhs a := undefined (lhs a).
Definition undefined_rhs a := undefined (rhs a).

(***********************************************************************)
(** properties *)

Lemma in_vcalls : forall x t n (ts : terms n),
  In x (calls t) -> Vin t ts -> In x (vcalls ts).

Proof.
induction ts; simpl; intros. contradiction. destruct H0.
subst t. apply in_appl. assumption. apply in_appr. apply IHts; assumption.
Qed.

Lemma in_vcalls_nil : forall x n (v : terms n),
  Vin x v -> vcalls v = nil -> calls x = nil.

Proof.
induction v; simpl; intros. contradiction.
ded (app_eq_nil _ _ H0). destruct H1.
destruct H. subst x. assumption. apply IHv; assumption.
Qed.

Lemma in_calls : forall x t, In x (calls t)
  -> exists g, exists vs, x = Fun g vs /\ defined g R = true.

Proof.
intros x t. pattern t. set (Q := fun n (ts : terms n) =>
  In x (vcalls ts) -> exists g, exists vs, x = Fun g vs /\ defined g R = true).
apply term_ind with (Q := Q); clear t.
simpl. intros. contradiction. intros f ts IH. rewrite calls_fun.
pattern (defined f R). apply bool_eq_ind; simpl; intros.
destruct H0. exists f. exists ts. auto. apply IH. assumption.
apply IH. assumption.
unfold Q. simpl. intro. contradiction.
unfold Q. simpl. intros. ded (in_app_or H1). intuition.
Qed.

Implicit Arguments in_calls [x t].

Lemma in_calls_defined : forall t g vs,
  In (Fun g vs) (calls t) -> defined g R = true.

Proof.
intros. ded (in_calls H). do 3 destruct H0. injection H0. intros. subst x.
assumption.
Qed.

Lemma in_calls_subterm : forall u t, In u (calls t) -> subterm_eq u t.

Proof.
intros u t. pattern t. set (Q := fun n (ts : terms n) =>
  In u (vcalls ts) -> exists t, Vin t ts /\ subterm_eq u t).
apply term_ind with (Q := Q); clear t.
(* var *)
simpl. intros. contradiction.
(* fun *)
intros f ts IH. rewrite calls_fun. case (defined f R); simpl; intro.
(* f defined *)
destruct H. rewrite H. apply subterm_eq_refl.
ded (IH H). destruct H0 as [t]. destruct H0. apply subterm_strict.
eapply subterm_trans_eq1. apply H1. apply subterm_fun. assumption.
(* f undefined *)
ded (IH H). destruct H0 as [t]. destruct H0. apply subterm_strict.
eapply subterm_trans_eq1. apply H1. apply subterm_fun. assumption.
(* nil *)
unfold Q. simpl. intros. contradiction.
(* cons *)
unfold Q. simpl. intros. ded (in_app_or H1). destruct H2.
ded (H H2). exists t. auto.
ded (H0 H2). destruct H3 as [w]. destruct H3. exists w. auto.
Qed.

Lemma subterm_in_calls : forall g us, defined g R = true
  -> forall t, subterm_eq (Fun g us) t -> In (Fun g us) (calls t).

Proof.
intros g us H t. pattern t. set (Q := fun n (ts : terms n) =>
  (exists t, Vin t ts /\ subterm_eq (Fun g us) t) -> In (Fun g us) (vcalls ts)).
apply term_ind with (Q := Q); clear t.
(* var *)
unfold subterm_eq. simpl. intros. destruct H0 as [C].
destruct C; simpl in H0; discriminate.
(* fun *)
intros f ts IH H0. unfold subterm_eq in H0. destruct H0 as [C].
rewrite calls_fun.
pattern (defined f R). apply bool_eq_ind; intro; destruct C; simpl in H0.
(* f defined *)
(* C = Hole *)
rewrite H0. apply in_eq.
(* C <> Hole *)
Funeqtac. subst ts. apply in_cons. apply IH. exists (fill C (Fun g us)). split.
apply Vin_cast_intro. apply Vin_app_cons. unfold subterm_eq. exists C. refl.
(* undefined f *)
(* C = Hole *)
injection H0. intros. subst f. rewrite H in H1. discriminate.
(* C <> Hole *)
Funeqtac. subst ts. apply IH. exists (fill C (Fun g us)). split.
apply Vin_cast_intro. apply Vin_app_cons. unfold subterm_eq. exists C. refl.
(* nil *)
unfold Q. simpl. intro. destruct H0 as [t]. intuition.
(* cons *)
intros t n ts H0 IH. unfold Q. simpl. intro H1. destruct H1 as [u].
do 2 destruct H1. subst u. apply in_appl. apply H0. assumption.
apply in_appr. apply IH. exists u. auto.
Qed.

End S.

Implicit Arguments in_calls [Sig R x t].
Implicit Arguments in_calls_defined [Sig R t g vs].
Implicit Arguments in_calls_subterm [Sig R u t].
