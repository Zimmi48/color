(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Joerg Endrullis, 2008-07-28
- Frederic Blanqui, 2007-02-05

union of two wellfounded relations
*)

Set Implicit Arguments.

Require Import SN RelUtil LogicUtil.

(***********************************************************************)
(** R @ S [<<] S @ R -> WF R -> WF S -> WF (R U S) *)

Require Import Lexico.

Module commut_prf.

  Section R1.

    Variable (A : Type) (gtA eqA gtA' : relation A)
      (eqA_trans : transitive eqA) (Hcomp : eqA @ gtA << gtA)
      (WF_gtA : WF gtA) (WF_gtA' : WF gtA').

    Definition R1 : relation A := fun x y => lex gtA eqA gtA' (x,x) (y,y).

    Lemma WF_R1 : WF R1.

    Proof. apply WF_inverse. apply WF_lex; hyp. Qed.

  End R1.

  Section R1'.

    Variable (A : Type) (gt1 gt2 : relation A)
      (WF_gt1 : WF gt1) (WF_gt2 : WF gt2)
      (trans_gt2 : transitive gt2) (Hcomp : gt2 @ gt1 << gt1).

    Definition R1' := R1 gt1 gt2 gt2.

    Lemma WF_R1' : WF R1'.

    Proof. unfold R1'. apply WF_R1; hyp. Qed.

    Lemma R1'_intro : gt1 U gt2 << R1'.

    Proof.
      unfold R1', R1, inclusion. intros. apply lex_intro. destruct H; auto.
    Qed.

  End R1'.

End commut_prf.

Section commut.

Variables (A : Type) (R S : relation A) (commut : R @ S << S @ R).

Lemma WF_union : WF R -> WF S -> WF (R U S).

Proof. Import commut_prf.
intros. eapply WF_incl. apply incl_tc. refl. eapply WF_incl. apply tc_union.
set (T := R# @ S). set (gt1 := T! @ R#). set (gt2 := R!).
eapply WF_incl. apply union_commut.
eapply WF_incl. apply R1'_intro. apply WF_R1'.
(* WF gt1 *)
unfold gt1. apply absorb_WF_modulo_r. incl_trans (R# @ T!). comp.
apply rtc_incl. unfold T. apply rtc_comp_modulo.
apply WF_tc. unfold T. apply WF_commut_modulo. exact commut. exact H0.
(* WF gt2 *)
unfold gt2. apply WF_tc. exact H.
(* transitive gt2 *)
apply trans_intro. unfold gt2. apply comp_tc_idem.
(* gt2 @ gt1 << gt1 *)
unfold gt1, gt2. assoc. comp. incl_trans (R# @ T!). comp. apply tc_incl_rtc.
unfold T. apply rtc_comp_modulo.
Qed.

End commut.

(***********************************************************************)
(* Additional Commutation Properties *)

Section Commutation_and_SN.

Variable (A : Type) (R S : relation A).

Lemma comm_s_rt : S@(R!1) << (R!1)@(S!1) -> (S!1)@(R!1) << (R!1)@(S!1).

Proof.
  intros comm x y [z [H1 H2]].
  induction H1 as [x z H | x y' z H H0 IH].
  apply comm. 
  exists z; split; hyp.
  assert (H1 := IH H2); clear IH H2.
  destruct H1 as [u [H2 H3]].
  assert ((clos_trans1 R @ clos_trans1 S) x u).
  apply comm. exists y'; split; hyp.
  destruct H1 as [m [xRm mSu]].
  exists m; split. hyp.
  exact (clos_trans1_trans mSu H3).
Qed.

Lemma comm_s_r : S@R << (R!1)@(S#1) ->
  (R U S)#1 @ R @ (R U S)#1 << (R!1) @ (R U S)#1.

Proof.
  intros comm x y [z2 [[z1 [xRSz1 z1Rz2] z2RSy]]].
  induction xRSz1 as [ | m n z1 mRSn nRSz1 IH].
  exists z2. split. apply t1_step. hyp. hyp.
  (* m RUS n RUS# z1 R z2 RUS# y *)
  assert (((R!1) @ (R U S)#1) n y) as mRedy. apply IH. hyp.
  (* m RUS n R!1@RUS#1 y *)
  clear nRSz1 z1Rz2 z2RSy IH z1 z2.
  destruct mRedy as [o [nRo oRSy]].
  (* m RUS n R!1 o RUS#1 y *)
  induction mRSn.
  (* m R n *)
    exists o. split; auto. apply t1_trans with n; hyp.
  (* m S n *)
    destruct nRo as [o p oRp | o p q oRp pRq ];

    assert (((R!1)@(S#1)) m p) as mRedp.
    apply comm. exists o; split; hyp.
    destruct mRedp as [x [mRx xSp]].
    exists x. split. hyp.
    apply clos_refl_trans1_trans with p.
    apply union_rel_rt_right. hyp. hyp.

    assert (((R!1)@(S#1)) m p) as mRedp.
    apply comm. exists o. split; hyp.
    destruct mRedp as [x [mRx xSp]].
    exists x. split. hyp. hyp.
    destruct mRedp as [n [mRn sSp]].
    exists n; split. hyp.
    apply clos_refl_trans1_trans with q.
    apply clos_refl_trans1_trans with p.
    apply union_rel_rt_right. hyp.
    apply union_rel_rt_left. apply incl_t_rt. hyp.    
    hyp.
Qed.

(***********************************************************************)
(* Commutation and SN *)

Lemma sn_comm_sntr :
  forall x, SN R x -> (forall y, (R#1) x y -> SN S y) ->
    (S@R << R!1@S#1) -> SN (R!1 U S!1) x.

Proof.
  intros x snr sns comm.
  assert (snrt := SN_tc1 snr); clear snr.

  (* Induction on x R! ... *)
  induction snrt as [x _ IHr].
  apply SN_intro. intros y xRSy.
  destruct xRSy as [xRy | xSy]. apply IHr. hyp.
  assert (SN (S!1) y) as sny.
  apply SN_tc1. apply sns. apply incl_t_rt; hyp.

  (* x R! y *)
  intros y0 yRy0. apply sns.
  apply incl_rt_rt_rt. exists y; split; trivial.
  apply incl_t_rt. hyp.

  (* x S! y *)
  assert (SN (S!1) y) as sny. apply SN_tc1.
  apply SN_rtc1 with x. apply sns. apply rt1_refl.
  apply incl_t_rt. hyp.

  (* Induction on y S! ... *)
  induction sny as [y _ IHs].
  apply SN_intro. intros z yRSz.
  destruct yRSz as [yRz | ySz].

  assert ((R!1 @ (R U S)#1) x z) as xRz.
    apply comm_s_r; trivial.
    destruct yRz as [y z yRz | y m z yRm mRz].
    exists z. split. exists y. split; trivial.
    apply union_rel_rt_right. apply incl_t_rt. hyp. apply rt1_refl.
    exists m. split. exists y. split; trivial.
    apply union_rel_rt_right. apply incl_t_rt. hyp.
    apply union_rel_rt_left. apply incl_t_rt. hyp.

  destruct xRz as [m [xRm mz]].
  assert (SN (R!1 U S!1) m) as SNm.
  apply IHr. hyp. intros y0 mRy0.
  apply sns. apply incl_rt_rt_rt. exists m.
  split; trivial. apply incl_t_rt. hyp.

  apply SN_rtc1 with m. hyp.
  apply incl_union_rtunion. hyp.
  apply IHs; trivial. apply clos_trans1_trans with y; trivial.
Qed.

Lemma sn_comm_sn :
  forall x, SN R x -> (forall y, (R#1) x y -> SN S y) ->
    (S@R << R!1@S#1) -> SN (R U S) x.

Proof.
  intros x snr sns comm.
  assert (SN (R!1 U S!1) x) as sntr.
  apply sn_comm_sntr; trivial.
  apply SN_incl with (R!1 U S!1).
  apply union_inclusion.
  intros a b. apply t1_step.
  intros a b. apply t1_step.
  hyp.
Qed.

End Commutation_and_SN.
