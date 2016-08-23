import 'package:built_collection/built_collection.dart';

import 'package:stranded/looped_event/looped_event.dart';
import 'package:stranded/storyline/storyline.dart';

import 'package:stranded/actor.dart';
import 'package:stranded/world.dart';
import 'package:stranded/planner.dart';
import 'package:stranded/action.dart';
import 'package:stranded/item.dart';
import 'package:stranded/plan_consequence.dart';
import 'package:stranded/team.dart';
import 'package:stranded/situation.dart';
import 'package:stranded/storyline/randomly.dart';
import 'package:edgehead/src/fight/fight_situation.dart';
import 'dart:async';
import 'dart:html';

class EdgeheadGame extends LoopedEvent {
  EdgeheadGame(StringTakingVoidFunction echo, StringTakingVoidFunction goto,
      choices, ChoiceFunction choiceFunction)
      : super(echo, goto, choices, choiceFunction) {
    setup();
  }

  Actor filip;
  Actor briana;
  Actor orc;
  Actor goblin;

  Situation initialSituation;
  WorldState world;
  PlanConsequence consequence;

  Storyline storyline = new Storyline();

  void setup() {
    filip = new Actor((b) => b
      ..id = 1
      ..isPlayer = true
      ..pronoun = Pronoun.YOU
      ..name = "Filip"
      ..currentWeapon = new Sword()
      ..initiative = 1000);
    briana = new Actor((b) => b
      ..id = 100
      ..pronoun = Pronoun.SHE
      ..name = "Briana"
      ..currentWeapon = new Sword("longsword"));

    orc = new Actor((b) => b
      ..id = 1000
      ..name = "orc"
      ..nameIsProperNoun = false
      ..pronoun = Pronoun.HE
      ..currentWeapon = new Sword("scimitar")
      ..team = defaultEnemyTeam);

    goblin = new Actor((b) => b
      ..id = 1001
      ..name = "goblin"
      ..nameIsProperNoun = false
      ..pronoun = Pronoun.HE
      ..currentWeapon = new Sword()
      ..team = defaultEnemyTeam);

    initialSituation = new Situation.withState(new FightSituation((b) => b
      ..playerTeamIds = new BuiltList<int>([filip.id, briana.id])
      ..enemyTeamIds = new BuiltList<int>([orc.id, goblin.id])
      ..events[2] = (w, s) {
        s.addParagraph();
        s.add("You hear a horrible growling sound from behind.");
        s.add("The worm must be near.");
        s.addParagraph();
      }
      ..events[6] = (w, s) {
        s.addParagraph();
        s.add("The earth shatters and there's that sound again.");
        s.addParagraph();
      }));

    world = new WorldState(
        new Set.from([filip, briana, orc, goblin]), initialSituation);

    consequence = new PlanConsequence.initial(world);
  }

  @override
  Future<Null> update() async {
    if (world.situations.isEmpty) {
      finished = true;

      storyline.addParagraph();
      if (world.getActorById(filip.id).isAlive) {
        storyline.add(
            "You look behind and see the giant worm's hideous head "
            "approaching. You start sprinting again.",
            wholeSentence: true);
        storyline.addParagraph();
        storyline.add("TO BE CONTINUED.", wholeSentence: true);
      } else {
        storyline.add("You will soon be the giant worm's food.",
            wholeSentence: true);
      }
      echo(storyline.toString());

      return;
    }
//    _choiceFunction("Do something", script: () => finished = true);

    var situation = world.currentSituation;
    var actor = situation.state.getCurrentActor(world);

    var planner = new ActorPlanner(actor, world);
    await planner.plan(
        maxOrder: 7,
        waitFunction: () async {
          await window.animationFrame;
        });
    var recs = planner.getRecommendations();
    if (recs.isEmpty) {
      // Hacky. Not sure this will work. Try to always have some action to do.
      world.updateSituationById(
          situation.id, (b) => b.state = b.state.elapseTime());
      world.time += 1;
      return;
    }

    ActorAction selected;
    if (actor.isPlayer) {
      // Player
      if (recs.actions.length == 1) {
        // Only one option, select by default.
        selected = recs.actions.single; // TODO
        _applySelected(selected, actor, storyline);
        return;
      }
      echo(storyline.toString());
      storyline.clear();

      planner.generateTable().forEach(print);
      for (ActorAction action in recs.actions) {
        choiceFunction(action.name, script: () {
          _applySelected(action, actor, storyline);
        });
      }
      return;
    } else {
//      XXX START HERE - if more than one action, remove the one that was just made
//      also rename to something else
      selected = recs.actions[Randomly.chooseWeightedPrecise(recs.weights,
          max: PlannerRecommendation.weightsResolution)];
      _applySelected(selected, actor, storyline);
    }
  }

  void _applySelected(ActorAction selected, Actor actor, Storyline storyline) {
    var consequences = selected.apply(actor, consequence, world).toList();
    int index = Randomly
        .chooseWeighted(consequences.map/*<num>*/((c) => c.probability));
    consequence = consequences[index];
    storyline.concatenate(consequence.storyline);
    world = consequence.world;
  }
}