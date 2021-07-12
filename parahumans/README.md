# Parahumans

> An open world simulation of the world of Worm with Time Travel thrown in for extra fun (and stress for the developer).

This is the main sub-project of the [egamebook][] project.
The major differences in this game from the previously published egamebook, Knights of San Francisco are:
* Modern world setting with modern technology
* Superpowers, superheroes, and supervillains
* Time travel based on the rough mechanics of the strategy game Achron
* Significantly larger location (an entire city)
* Significantly more NPCs

Major influences and references:
* The [egamebook][] project by Filip Hracek
* The world of [Worm][], a web published serial fiction authored by Wildbow
* The game [Achron][], a 2011 strategy game with a novel time-travel mechanic

[egamebook]: https://egamebook.com
[Worm]: https://parahumans.wordpress.com
[Achron]: https://www.achrongame.com

## Development

### Installation

1. [Install Dart](https://www.dartlang.org/install)
   * Use Dart 2 stable (which is the default as of August 2018).
1. Clone this repository (`git clone https://github.com/deinspanjer/egamebook.git`)
1. Go to the repository's directory (`cd egamebook`)
1. Switch to the parahumans branch (`git checkout parahumans`)
1. Go to the `parahumans` sub-project (`cd parahumans`)
1. Install Dart packages (`dart pub get`)

Now you can try running tests (`dart pub run test`) or play the game on the command
line (`dart --enable-asserts bin/play.dart --log`).

### Playtesting

First of all, thank you. Even by just _thinking_ about helping this project
by playtesting means you genuinely want to see the game finished and successful,
and that means a lot to me.

If you want to get a sense of what games created in this platform feel like, I recommend playing the 
web-based game [Insignificant Little Vermin](https://egamebook.com/vermin) (an early prototype),
or Filip's awesome fantasy game, [Knights of San Francisco](https://egamebook.com/knights/).

To playtest the current version of the game, install it
([see above](#installation)), and in the `egamebook/parahumans` sub-directory, run:

```bash
dart --enable-asserts bin/play.dart --log
```

You will be able to choose from options by using the arrow keys and hitting
`enter` or `space`.

![Animated screenshot of the CLI menu](https://raw.githubusercontent.com/filiph/cli_menu/master/example/mac_screencast.gif)

Output will be presented in raw Markdown text format, punctuated with
"UI" things like the slot machine (which, in text, looks rather
underwhelming, something like `[[ SLOT MACHINE 'Will you succeed?' 0.98 ]]`).

#### Debug cheat codes

Normally, if you choose an action that depends on chance,
the game will "throw dice" (use randomness). In the command line interface,
this happens in less than a millisecond, but it does happen.

You can force each option to either succeed or fail by using a key other
than the default `enter` or `space`. By navigating to your chosen 
option and pressing `s`, that action will succeed no matter how low your odds
are. By pressing `f`, that action will fail. (Mnemonic: `s` is for
success, `f` is for fail.) You will not see the `[[ SLOT MACHINE ... ]]`
output in either case.

Ultimately, you should default to playtesting *without* these cheats. 
If playing the game is only fun when you can force each action to succeed
or fail, then the game is broken. But the cheats are useful for predictably
getting yourself into an interesting situation, and for seeing "what happens". 

#### What to playtest

1. Accurate descriptions of known characters
1. A fun perspective of the city (balance of realistic vs feasible to visualize and navigate)
1. A fun implementation of the use of superpowers in and out of combat

#### How to give feedback

Create a new issue in the [Github project](https://github.com/deinspanjer/egamebook/issues)

If it's a bug report, please attach the `parahumans.log` (which you'll find
in the game's root directory, and which gets rewritten every time you play) 
and at least the last page of the command
line output (screenshot, text file or copy-paste). You can attach files
to issues by dragging and dropping them.

### Development flow

Run the following when developing:

    pub run build_runner watch --delete-conflicting-outputs
    
This will make sure that generated files (`*.g.dart`) are regenerated when
needed.

Most writing is in text files in the `assets/text/` directory. 
When the `pub run build_runner watch` watcher is running, it will, among other
things, watch for changes of the text files. It will compile the texts into the 
`lib/writers_input.compiled.dart` file, which is then used by the game itself.

It is sometimes possible to get the source generation in a bad state. This
might manifest in build failures such as:

    Error in BuiltValueGenerator for /edgehead/lib/edgehead_serializers.dart.
    Broken @SerializersFor annotation. Are all the types imported?

This is often caused by an earlier problem (for example, hitting save while
your `egb.txt` files are in some in-between state), which makes the source
generator build the files in the wrong order. The remedy is to run:

    pub run build_runner clean

After this, run the `pub run build_runner watch` command again and all should
be good. 

Most behavior and game-related code is in the other files in `lib/`. You
might want to start with `lib/edgehead_lib.dart`.  

To test, run `pub run test`, and to include long-running fuzzy tests,
run `pub run --enable-asserts test --run-skipped`.

#### Debug play-testing

If you use an IDE that lets you attach the debugger to a port, you might want
to run the playtest in regular console and attach to it. To do that, execute
this command:

    dart --enable-asserts --enable-vm-service:5858 --disable-service-auth-codes bin/play.dart

The port number is up to you. I use `5858` as a convention. The
`disable-service-auth-codes` flag makes your debug less safe (but way more
convenient).

Now, you can start the debug. For example, in IntelliJ editors, there's a run
configuration template called "Dart Remote Debug". You just need to set it
up for `localhost` and port `5858`.

Once both the executable and the debug are running, you can play as you normally
would in the terminal window, and attach breakpoints, see output and inspect
variables in the IDE.

### Testing

Run `pub run test` or setup your IDE for continuous unit testing.

Also included are long-running tests that are skipped by default. These
tests are "fuzzy" -- meaning that they will try to play the game randomly until
completion or error. 

Run all the tests, including the long-running ones, using this command:

    pub run --enable-asserts test --run-skipped
    
The `--enable-asserts` flag tells Dart to run assertions and generally be more 
fail-fast. It also makes the code run a few percent slower.

### Playing on the command line

Run `dart bin/play.dart` if you just want to play. But consider using the
following command to also log progress and catch more bugs through checked mode:

    dart --enable-asserts bin/play.dart --log

The log is in `parahumans.log`. Remove `--log` for better performance.

Use up and down arrows to choose options, enter to select.

#### Playtesting actions

When you are ready to play-test your new action, run this command:

    dart --enable-asserts bin/play.dart --log --automated --action example
    
This will play automatically (randomly) until the player character reaches
a point in which he can choose an action which name includes `example`. Then,
the game switches to interactive mode.

This is a much faster way to get to your actions. The alternative is to play
towards that action manually, which takes much more time.

