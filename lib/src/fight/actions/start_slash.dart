import 'package:edgehead/fractal_stories/action.dart';
import 'package:edgehead/fractal_stories/actor.dart';
import 'package:edgehead/fractal_stories/situation.dart';
import 'package:edgehead/fractal_stories/storyline/storyline.dart';
import 'package:edgehead/fractal_stories/simulation.dart';
import 'package:edgehead/fractal_stories/world_state.dart';
import 'package:edgehead/src/fight/actions/start_defensible_action.dart';
import 'package:edgehead/src/fight/common/conflict_chance.dart';
import 'package:edgehead/src/fight/common/weapon_as_object2.dart';
import 'package:edgehead/src/fight/slash/slash_defense/slash_defense_situation.dart';
import 'package:edgehead/src/fight/slash/slash_situation.dart';
import 'package:edgehead/src/predetermined_result.dart';

const String startSlashCommandTemplate = "swing at <object>";

const String startSlashHelpMessage =
    "The basic swordfighting move is also often the "
    "most effective.";

/// There are several ways to defend against a slash. But, for simplicity,
/// _player's_ slash will assume an average effort from the defender,
/// and will compute a predetermined result from that.
///
/// The reaction is then basically selected randomly. Because success/failure
/// are predetermined, there is little difference for the planner between
/// the various defense moves.
ReasonedSuccessChance computeStartSlashPlayer(
    Actor a, Simulation sim, WorldState w, Actor enemy) {
  return getCombatMoveChance(a, enemy, 0.5, [
    const Bonus(50, CombatReason.dexterity),
    const Bonus(30, CombatReason.targetWithoutShield),
    const Bonus(30, CombatReason.balance),
  ]);
}

EnemyTargetAction startSlashBuilder(Actor enemy) => new StartDefensibleAction(
    "StartSlash",
    startSlashCommandTemplate,
    startSlashHelpMessage,
    startSlashReportStart,
    (a, sim, w, enemy) =>
        !a.isPlayer &&
        a.isStanding &&
        !enemy.isOnGround &&
        a.currentWeapon.damageCapability.isSlashing,
    (a, sim, w, enemy) => createSlashSituation(w.randomInt(), a, enemy),
    (a, sim, w, enemy) => createSlashDefenseSituation(
        w.randomInt(), a, enemy, Predetermination.none),
    enemy);

EnemyTargetAction
    startSlashPlayerBuilder(Actor enemy) =>
        new StartDefensibleAction(
            "StartSlashPlayer",
            startSlashCommandTemplate,
            startSlashHelpMessage,
            startSlashReportStart,
            (a, sim, w, enemy) =>
                a.isPlayer &&
                a.isStanding &&
                !enemy.isOnGround &&
                a.currentWeapon.damageCapability.isSlashing,
            (a, sim, w, enemy) => createSlashSituation(w.randomInt(), a, enemy),
            (a, sim, w, enemy) => createSlashDefenseSituation(
                w.randomInt(), a, enemy, Predetermination.failureGuaranteed),
            enemy,
            successChanceGetter: computeStartSlashPlayer,
            applyStartOfFailure: startSlashReportStart,
            defenseSituationWhenFailed:
                (a, sim, w, enemy) => createSlashDefenseSituation(w.randomInt(),
                    a, enemy, Predetermination.successGuaranteed),
            rerollable: true,
            rerollResource: Resource.stamina,
            rollReasonTemplate: "will <subject> hit <objectPronoun>?");

void startSlashReportStart(Actor a, Simulation sim, WorldStateBuilder w,
        Storyline s, Actor enemy, Situation mainSituation) =>
    a.report(s, "<subject> swing<s> {${weaponAsObject2(a)} |}at <object>",
        object: enemy,
        actionThread: mainSituation.id,
        isSupportiveActionInThread: true);
