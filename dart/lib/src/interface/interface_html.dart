library egb_interface_html;

import 'dart:async';
import 'dart:html';

import '../shared/markdown.dart' show markdown_to_html;

import 'interface.dart';
import '../persistence/savegame.dart';
import '../shared/user_interaction.dart';

// because we're defining localStorage here
import '../persistence/storage.dart';
import '../persistence/player_profile.dart';

import 'choice_with_infochips.dart';

class HtmlInterface implements EgbInterface {

  AnchorElement restartAnchor;
  
  DivElement bookDiv;
  
  StreamController<PlayerIntent> _streamController;
  Stream get stream => _streamController.stream;
  
  /**
   * The text that has been shown to the player since last savegame bookmark.
   * (Markdown format, pre-HTMLization.)
   */
  StringBuffer _textHistory = new StringBuffer();
  String getTextHistory() => _textHistory.toString();
  
  /**
    Constructor.
    */
  HtmlInterface() {
    _streamController = new StreamController();
  }
  
  void setup() {
    // DOM
    bookDiv = document.query("div#book-wrapper");

    restartAnchor = document.query("nav a#book-restart");
    restartAnchor.onClick.listen((_) {
      _streamController.sink.add(new RestartIntent());
      // Clear text and choices
      bookDiv.children.clear();
      _textHistory.clear();
    });
    
    document.query("p#loading").remove();
  }
  
  void close() {
    _streamController.close();
  }
  
  Future<bool> showText(String s) {
    _textHistory.writeln("$s\n");
    String html = markdown_to_html(s);
    DivElement div = new DivElement();
    div.innerHtml = html;
    _recursiveRemoveScript(div);
    bookDiv.append(div);  // TODO: one by one, wait for transition end
    return new Future.value(true);
  }
  
  /**
   * Goes through DOM Element and removes any Script Elements (recursively).
   * 
   * Currently silent.
   */
  void _recursiveRemoveScript(Element e) {
    if (e is ScriptElement) {
      print("Script detected!");
      e.remove();
    } else if (e.children.length > 0) {
      for (int i = 0; i < e.children.length; i++) {
        _recursiveRemoveScript(e.children[i]);
      }
    }
  }

  Future<int> showChoices(EgbChoiceList choiceList) {
    var completer = new Completer();
    
    var choicesDiv = new DivElement();
    choicesDiv.classes.add("choices-div");
    
    if (choiceList.question != null) {
      var choicesQuestionP = new ParagraphElement();
      choicesQuestionP.innerHtml = markdown_to_html(choiceList.question);
      choicesQuestionP.classes.add("choices-question");
      choicesDiv.children.add(choicesQuestionP);
    }
    
    OListElement choicesOl = new OListElement();
    choicesOl.classes.add("choices-ol");
    
    // let player choose
    for (int i = 0; i < choiceList.length; i++) {
      EgbChoice choice = choiceList[i];
      LIElement li = new Element.tag("li");

      var number = new SpanElement();
      number.text = "$i";
      number.classes.add("choice-number");
      
      var choiceDisplay = new SpanElement();
      var choiceWithInfochips = new ChoiceWithInfochips(choice.string);
      var text = new SpanElement();
      text.innerHtml = markdown_to_html(choiceWithInfochips.text);
      text.classes.add("choice-text");
      choiceDisplay.append(text);
      
      if (!choiceWithInfochips.infochips.isEmpty) {
        var infochips = new SpanElement();
        infochips.classes.add("choice-infochips");
        for (int j = 0; j < choiceWithInfochips.infochips.length; j++) {
          var chip = new SpanElement();
          chip.innerHtml = markdown_to_html(choiceWithInfochips.infochips[j]);
          chip.classes.add("choice-infochip");
          infochips.append(chip);
        }
        choiceDisplay.append(infochips);
      }

      li.onClick.listen((Event ev) {
          // Send choice hash back to Scripter.
          completer.complete(choice.hash);
          // Mark this element as chosen.
          li.classes.add("chosen");
      });
      
      li.append(number);
      li.append(choiceDisplay);
      
      choicesOl.append(li);
    }
    
    choicesDiv.append(choicesOl);
    
    _recursiveRemoveScript(choicesDiv);
    bookDiv.append(choicesDiv);
    return completer.future;
  }
  
  /**
   * Makes choices in ordered list [choicesDiv] unclickable (removes <a> tags).
   * When the element has [:savegame-uid:] data attribute set, then the list
   * becomes a "bookmark" - saved state can be loaded by clicking on it.
   */
  void _makeIntoBookmark(DivElement choicesDiv) {
    choicesDiv.classes.add("past");
    // Remove <a> tags from all choices.
    choicesDiv.query("ol.choices-ol").children.forEach((LIElement el) {
      var string = el.query("a").innerHtml;
      el.children.clear();
      el.innerHtml = string;
    });
    if (choicesDiv.dataset.containsKey("savegame-uid")) {
      String uid = choicesDiv.dataset["savegame-uid"];
      // Make possible to come back to the associated savegame.
      choicesDiv.onClick
      .listen((Event ev) {
        // TODO: make more elegant, with confirmation appearing on page
        _handleSavegameBookmarkClick(uid, choicesDiv);
      });
    }
  }

  /**
   * What happens when user clicks on a savegame bookmark.
   */
  void _handleSavegameBookmarkClick(String uid) {
    // TODO: make more elegant, with confirmation appearing on page
    var confirm = window.confirm("Are you sure you want to come back to "
                    "this decision ($uid) and lose your progress since?");
    if (confirm) {
      bookDiv.children.clear();
      // TODO: retain scroll position
      _streamController.sink.add(new LoadIntent(uid));
    }
  }
  
  Future<bool> addSavegameBookmark(EgbSavegame savegame) {
    print("Creating savegame bookmark for ${savegame.uid}");
    _textHistory.clear();  // The _textHistory has been saved with the savegame.
    var bookmarkDiv = new DivElement();
    bookmarkDiv.id = "bookmark-uid-${savegame.uid}";
    bookmarkDiv.classes.add("bookmark-div");
    var bookmarkAnchor = new AnchorElement();
    bookmarkAnchor.text = "Load [${savegame.uid}]";
    bookmarkAnchor.onClick.listen((_) {
      _handleSavegameBookmarkClick(savegame.uid);
    });
    bookmarkDiv.append(bookmarkAnchor);
    bookDiv.append(bookmarkDiv);
  }
}

class LocalStorage implements EgbStorage {
  Future<bool> save(String key, String value) {
    window.localStorage[key] = value;
    return new Future.value(true);
  }
  
  Future<String> load(String key) {
    var result = window.localStorage[key];
    return new Future.value(result);
  }
  
  Future<bool> delete(String key) {
    window.localStorage.remove(key);
    return new Future.value(true);
  }
  
  EgbPlayerProfile getDefaultPlayerProfile() {
    return new EgbPlayerProfile(EgbStorage.DEFAULT_PLAYER_UID, 
        this);
  }
}
