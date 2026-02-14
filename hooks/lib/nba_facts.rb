# frozen_string_literal: true

# NbaFacts - Categorized NBA and NBA Jam trivia for session startup
# 175+ curated facts across 6 categories, punchy social media style (~160 char max)

module NbaFacts
  CATEGORY_EMOJIS = {
    jam_arcade:     "\u{1F579}\uFE0F",
    jam_franchise:  "\u{1F3AE}",
    jam_culture:    "\u{1F4B0}",
    iconic_moments: "\u{1F3C0}",
    player_quotes:  "\u{1F4AC}",
    oddities:       "\u{1F92F}"
  }.freeze

  CATEGORY_NAMES = {
    jam_arcade:     'ARCADE LORE',
    jam_franchise:  'JAM HISTORY',
    jam_culture:    'CULTURAL IMPACT',
    iconic_moments: 'NBA HISTORY',
    player_quotes:  'THEY SAID WHAT',
    oddities:       'WAIT WHAT'
  }.freeze

  REACTIONS = {
    jam_arcade: [
      "The devs were absolutely unhinged.",
      "This man woke up every day and chose violence.",
      "Peak 90s game dev energy.",
      "They don't make 'em like this anymore.",
      "Someone was having way too much fun at work.",
      "This actually shipped. In an actual game.",
      "The QA team was in on it.",
      "90s arcade culture was a different breed."
    ].freeze,

    jam_franchise: [
      "Gaming was just different back then.",
      "The franchise stays winning.",
      "Port wars were the original console wars.",
      "That's some big cartridge energy.",
      "The legacy is real.",
      "They kept cooking and it kept working.",
      "Every console got a taste.",
      "The franchise refused to stay down."
    ].freeze,

    jam_culture: [
      "Let that sink in.",
      "Read that number again. Slowly.",
      "This changed the whole game. Literally.",
      "An arcade cabinet did THAT.",
      "The culture was never the same.",
      "Mainstream didn't know what hit it.",
      "That's not a game. That's a movement.",
      "The ripple effect is still going."
    ].freeze,

    iconic_moments: [
      "Still gives me chills.",
      "You had to be there. But this is close.",
      "Legendary doesn't even cover it.",
      "This is why we watch basketball.",
      "The building went absolutely silent.",
      "Nobody moved. Nobody breathed.",
      "Certified bucket. Hall of Fame moment.",
      "Rewatch this clip. Then rewatch it again."
    ].freeze,

    player_quotes: [
      "Absolutely zero filter.",
      "The audacity of this man.",
      "Mic. Dropped. Floor. Shook.",
      "They said it with their whole chest.",
      "PR team in shambles after this one.",
      "No notes. Just vibes.",
      "This quote lives rent-free in my head.",
      "The confidence is frankly inspiring."
    ].freeze,

    oddities: [
      "I'm not making this up. Google it.",
      "I'll give you a minute with that one.",
      "How is this real. How is any of this real.",
      "The NBA is basically a sitcom.",
      "No writer's room could script this.",
      "This feels illegal but technically it's just basketball.",
      "The timeline we're living in is wild.",
      "Even the NBA was confused by this one."
    ].freeze
  }.freeze

  FACTS_BY_CATEGORY = {
    # ─── NBA Jam Arcade (1993 original) ──────────────────────────────────
    jam_arcade: [
      "NBA Jam's creator was a Pistons fan. He secretly coded the Bulls to miss clutch shots. In a shipped game.",
      "$2,400 a week. In quarters. From a single NBA Jam cabinet.",
      "NBA Jam used real NBA player photos. They filmed each head on a rotating platform like a mugshot.",
      "Tim Kitzrow recorded BOOMSHAKALAKA in one take. First try. That's the one that shipped.",
      "NBA Jam literally cheated for the losing team. Hidden rubber-banding gave trailing squads invisible boosts.",
      "Bill Clinton was a hidden character in NBA Jam. The sitting President. Dunking on Barkley.",
      "Al Gore, Prince Charles, and Heavy D were all secretly playable in NBA Jam. In 1993.",
      "NBA Jam cabinets got real NBA stat updates via modem. Weekly. In 1993. On an arcade machine.",
      "The original NBA Jam had no visible three-point line. You just had to know where it was.",
      "NBA Jam was written in raw assembly language. Every frame hand-optimized for Midway's hardware.",
      "NBA Jam devs played so many test games they could beat the AI without looking at the screen.",
      "Backboard-shattering dunks weren't in the original plan. Testers said normal dunks felt boring. They were right.",
      "The fire trail behind the ball? Four animation frames. Total. ROM space was that tight.",
      "NBA Jam removed goaltending on purpose. Why? Because swatting shots at the rim is way more fun.",
      "Three buckets in a row and you catch fire. The mechanic was inspired by real basketball hot streaks.",
      "NBA Jam's attract mode pulled more quarters than any sports game before it. Just by being on screen.",
      "Every NBA Jam cabinet shipped with a coin counter. Midway was tracking revenue per machine nationwide.",
      "The turbo meter was a last-minute addition. It completely changed the game's pacing — for the better.",
      "NBA Jam ran at 54 FPS in 1993. Most arcade games weren't even close to that smooth.",
      "Mark Turmell hid a code that made the Pistons nearly unbeatable at home. His team. His code. His rules.",
      "NBA Jam's scaling sprites made dunkers look like they were flying 20 feet above the rim. On purpose.",
      "Over 200 digitized voice clips on a single sound board. All Tim Kitzrow. All iconic.",
      "Midway tested NBA Jam at one Chicago arcade before rolling it out nationwide. One location. Then everywhere.",
      "The original code had a bug where player heads randomly swapped mid-game. Just... switched faces.",
      "NBA Jam is 2-on-2 because full teams wouldn't fit in memory. A hardware limitation became the identity.",
      "Gary Payton's speed was maxed at 10. Highest of any player in the game. The Glove was untouchable.",
      "Scottie Pippen was in NBA Jam. MJ was not. Why? Jordan had his own licensing deal. No exceptions.",
      "NBA Jam was the first arcade game with real-time stat tracking between sessions. In 1993.",
      "No shot clock. On purpose. Midway wanted the pace frantic and the quarters flowing.",
      "Midway tested 3-on-3 first. 2-on-2 won because it ate more quarters. Money talks.",
      "NBA Jam's code had hidden developer initials you could unlock with secret button combos.",
      "Collision detection was intentionally loose. Why? So block animations could look spectacular.",
      "NBA Jam made more money in 1993 than any other arcade game in North America. Number one.",
      "Tim Kitzrow recorded over 300 unique lines for NBA Jam. Three hundred. For an arcade game.",
      "\"Is it the shoes?\" was a direct Nike reference. Mars Blackmon. Spike Lee. Straight into the arcade."
    ].freeze,

    # ─── NBA Jam Franchise (sequels, ports, revivals) ────────────────────
    jam_franchise: [
      "Tournament Edition added 3 players per team and a fatigue system. The sequel got deeper.",
      "NBA Jam TE had over 40 hidden characters. Fresh Prince and DJ Jazzy Jeff were both playable. Both.",
      "The SNES version of NBA Jam sold over 5 million copies. A 16-bit arcade port. Five million.",
      "NBA Jam: On Fire Edition brought Tim Kitzrow back in 2010. New lines. Same voice. Still iconic.",
      "NBA Hangtime dropped in '96 with create-a-player. Custom attributes. Custom heads. Your face in the game.",
      "Genesis and SNES had different NBA Jam rosters. Same game, different squads depending on your console.",
      "NBA Jam Extreme tried to go 3D in 1996. Fans hated it. Some things should stay in 2D.",
      "EA revived NBA Jam in 2010 as a downloadable title. Nostalgia is a powerful business model.",
      "They put NBA Jam on the Game Boy. Tiny screen. Surprisingly faithful. Nobody expected it to work.",
      "Tournament Edition added \"Hot Spots\" — court zones that gave bonus points. Every shot location mattered.",
      "NBA Jam on Atari Jaguar was one of the few games that made owning a Jaguar worth it.",
      "NBA Hangtime let you save custom players to the arcade cabinet with a PIN code. In 1996.",
      "The 32X version of NBA Jam was considered one of the best console ports. The 32X finally had a win.",
      "On Fire Edition added Tag Mode — switch between all your team's players mid-game. Total control.",
      "Tournament Edition could injure your best player for multiple quarters. One bad hit and your star is gone.",
      "The 3DO version had full-motion video intros. No other console port got them. 3DO exclusive flex.",
      "NBA Jam TE tracked tournament wins across sessions using passcodes. No memory card needed. Just a code.",
      "NBA Hangtime was the last NBA Jam-style game Midway put in arcades. End of an era.",
      "EA's 2010 revival had a Remix Tour mode with power-ups and boss battles. NBA Jam went full arcade RPG.",
      "The Game Gear port ran at half the frame rate but kept every single voice clip. Priorities.",
      "Tournament Edition fixed the Pistons bias. Sort of. Turmell says he \"toned it down.\" Sure, Mark.",
      "NBA Jam TE added Power-Up mode — grab icons on the court for temporary abilities. Chaos.",
      "The Saturn port of NBA Jam TE was Japan-exclusive. Extremely rare. Good luck finding one.",
      "NBA Jam has sold over 10 million copies across all platforms. Quarters to cartridges to downloads.",
      "On Fire Edition had online multiplayer. First time you could play NBA Jam competitively over the internet."
    ].freeze,

    # ─── NBA Jam Cultural Impact ─────────────────────────────────────────
    jam_culture: [
      "$1 billion in quarters. In one year. From a single arcade game. NBA Jam was a money printer.",
      "NBA Jam made more money in arcades than Jurassic Park made in theaters. Read that again.",
      "BOOMSHAKALAKA was in slang dictionaries by 1995. An arcade announcer changed the English language.",
      "NBA Jam was so massive it spawned NFL Blitz, NHL Hitz, and MLB Slugfest. One game built an empire.",
      "Every arcade sports announcer you've ever heard is doing a Tim Kitzrow impression. He set the template.",
      "One arcade in Chicago had 14 NBA Jam cabinets running at once. Fourteen. In one building.",
      "NBA Jam got referenced in over 30 TV shows and movies in the 90s. It wasn't a game. It was a moment.",
      "\"He's on fire!\" jumped from the arcade to actual NBA broadcasts. Commentators stole from a video game.",
      "NBA Jam introduced millions of people to basketball. Not the NBA. Not ESPN. An arcade cabinet.",
      "Midway's stock price doubled after NBA Jam dropped. A $0.50 arcade game moved Wall Street.",
      "NBA Jam made the NBA realize video games were marketing gold. Every NBA game license traces back to it.",
      "NBA Street and AND1 Mixtape owe their entire vibe to NBA Jam. Over-the-top basketball started here.",
      "\"From downtown!\" became real basketball slang partly because an arcade game yelled it first.",
      "NBA Jam shirts, hats, and posters were selling in malls nationwide in 1994. Arcade merch. In malls.",
      "Multiple NBA players say their introduction to basketball was NBA Jam. Not pickup games. An arcade.",
      "NBA Jam was so culturally significant that ESPN made a full documentary about how it was built.",
      "NBA Jam announcer calls have been sampled in hundreds of hip-hop tracks from the 90s to today.",
      "Pizza Hut gave out NBA Jam arcade tokens with pizza purchases. Peak 90s cross-promotion.",
      "NBA Jam was the first game most Gen X kids played that used real athlete names and likenesses.",
      "That \"Boom\" sound from NBA Jam dunks? It became a staple in 90s TV commercials. You've heard it."
    ].freeze,

    # ─── Iconic NBA Moments ──────────────────────────────────────────────
    iconic_moments: [
      "Wilt dropped 100 points in a single game. March 2, 1962. No TV footage exists. Just the legend.",
      "Jordan's last shot as a Bull. Over Bryon Russell. Game 6. Ring number 6. The perfect ending.",
      "Magic announced he was HIV positive in 1991. Months later he made the All-Star team.",
      "Larry Bird told defenders exactly where he'd shoot from. Then hit the shot. Every time.",
      "The '92 Dream Team won Olympic games by an average of 43.8 points. It wasn't competition. It was a showcase.",
      "Kawhi's Game 7 buzzer beater bounced on the rim four times before dropping. Four bounces. Series over.",
      "Dame Lillard. 37 feet. 0.9 seconds left. Series over. OKC eliminated from the logo.",
      "Reggie Miller scored 8 points in 8.9 seconds against the Knicks. Not a typo. Eight-point-nine seconds.",
      "Iverson hit the jumper, then stepped over Tyronn Lue in the Finals. The most disrespectful highlight ever.",
      "Tim Duncan's bank shot in 2008 hit every part of the rim and rolled out. The greatest near-miss ever filmed.",
      "LeBron chased down Iguodala from behind in Game 7 of the 2016 Finals. The block that saved Cleveland.",
      "Jordan switched hands mid-air on a layup against the Lakers in the '91 Finals. Mid. Air.",
      "Kobe dropped 81 points on the Raptors. Eighty-one. Second only to Wilt's 100 in NBA history.",
      "Russell Westbrook averaged a triple-double for three straight seasons. Not one game. Three whole seasons.",
      "Steph Curry hit 402 threes in 2015-16. Broke his own record by 116 makes. Broke it by accident.",
      "The Malice at the Palace in 2004 was so wild it rewrote the NBA's fan conduct rules entirely.",
      "Hakeem's Dream Shake was so unstoppable it inspired an entire generation of big men to learn footwork.",
      "Jordan dropped 63 on the Celtics in '86. Bird said: \"That was God disguised as Michael Jordan.\"",
      "The 2016 Cavs came back from 3-1 down against the 73-win Warriors. No team had ever done that in the Finals.",
      "Dirk's one-legged fadeaway carried Dallas past LeBron's superteam for the 2011 title. Unguardable.",
      "Willis Reed could barely walk. He limped onto the court for Game 7 in 1970. The Knicks won the title.",
      "Kareem's skyhook was released from so high up that no defender in NBA history consistently blocked it.",
      "LeBron passed Kareem as the all-time leading scorer in February 2023. The record stood for 39 years.",
      "T-Mac scored 13 points in 35 seconds against the Spurs. The game was over and then it wasn't.",
      "Derek Fisher hit a buzzer beater with 0.4 seconds left. They said it was impossible to shoot that fast.",
      "Bill Russell won 11 championships in 13 seasons. Eleven. The most dominant run in sports history.",
      "Vince Carter dunked between his legs in the 2000 Slam Dunk Contest. The arena lost its mind.",
      "Celtics vs Lakers. 12 Finals meetings. The greatest rivalry in NBA history and it's not close.",
      "Dennis Rodman grabbed 34 rebounds in a single game. The man was 6'7\" playing with 7-footers.",
      "Shaq missed 5,317 free throws in his career. More misses than most players ever attempt total.",
      "Steph Curry won the 2016 MVP unanimously. First time ever. Every single voter picked the same guy.",
      "The '95-96 Bulls went 72-10. That record stood for 20 years until the Warriors went 73-9. Then lost.",
      "Isaiah Thomas scored 25 in the 4th quarter of an elimination game on a bad ankle. Heart over body.",
      "Robert Horry hit so many clutch playoff shots they called him Big Shot Rob. He has 7 rings.",
      "KG's pregame intensity was so legendary his own teammates were scared of his speeches.",
      "Ray Allen's corner three in Game 6 of the 2013 Finals. Rebound. Back out. Bang. The Heat survive.",
      "Devin Booker dropped 70 points at age 20. The youngest player to ever reach that number.",
      "Luka hit a one-legged three at the buzzer in the 2020 playoff bubble. Step-back. One leg. Bucket.",
      "Giannis dropped 50 in a Finals closeout game in 2021. Fifty points to win a championship. All-time.",
      "Magic played center as a rookie in Game 6 of the 1980 Finals. Dropped 42. He was twenty years old."
    ].freeze,

    # ─── Player Quotes ───────────────────────────────────────────────────
    player_quotes: [
      "Larry Bird walked into the 3-point contest and asked \"Who's coming in second?\" Before shooting.",
      "\"We talkin' about practice. Not a game. Practice.\" Iverson said it 22 times in one presser. Legend.",
      "Antoine Walker on why he shoots so many threes: \"Because there are no fours.\"",
      "Rasheed Wallace yelled \"Ball don't lie\" every time an opponent bricked a free throw. Every. Single. Time.",
      "MJ: \"I've missed 9,000 shots. Lost 300 games. Failed over and over. That is why I succeed.\"",
      "Shaq compared his free throw shooting to the Pythagorean theorem. His reason? \"Not easy to figure out.\"",
      "KG won his first title in 2008 and screamed \"ANYTHING IS POSSIBLE\" so loud it broke the broadcast.",
      "Kobe was up 2-0 in the Finals. Reporter asked how it felt. His response: \"Job's not finished.\"",
      "LeBron in a press conference: \"I'm not gonna say I'm a model citizen. I'm LeBron James.\"",
      "Barkley's 1993 Nike ad: \"I am not a role model. Parents should be role models.\" Nike actually aired that.",
      "Tim Duncan said \"Good call\" to a ref. Got a technical foul. The crime? Sarcasm.",
      "Steph after winning the Finals over Boston: \"What are they gonna say now?\" Cold.",
      "Westbrook: \"I don't care what people say. I play for my teammates.\" Then averaged a triple-double. Again.",
      "Harden: \"I'm the best player in the world. Why wouldn't I believe that?\" Zero hesitation.",
      "Draymond Green: \"They don't love you until you leave.\" Then paused. \"I'm not leaving.\"",
      "Pat Riley didn't just say \"Three-peat.\" He trademarked it. In 1988. The man owns the word.",
      "Kevin Durant got caught tweeting from burner accounts defending himself. Against random fans.",
      "Dennis Rodman skipped practice to wrestle Hulk Hogan on live TV. The man was uncoachable in the best way.",
      "Shaq dropped 4 rap albums. His debut went platinum in 1993. Sold a million records AND dunked on you.",
      "\"It ain't over till it's over.\" Yogi Berra said it first. Every NBA coach has stolen it since.",
      "Jimmy Butler screamed \"You f***ing need me\" at his own teammates during practice. Then proved it.",
      "Bill Walton called a random play \"the greatest thing since the invention of the wheel.\" Peak Bill Walton.",
      "Reggie Miller hit a three over Spike Lee, turned to him courtside, and just smiled. No words needed.",
      "Larry Bird played an entire game left-handed. Why? He felt the Trail Blazers weren't a real challenge.",
      "Gary Payton's trash talk was so brutal that opponents literally requested not to guard him.",
      "Paul Pierce hit a buzzer beater, turned to the camera, and said \"I called game.\" Because he did.",
      "Dirk after clinching a playoff series: \"Shut it down. Let's go home!\" Then actually went home.",
      "Joel Embiid named himself \"The Process\" after Philly's tanking strategy. Turned the meme into a brand.",
      "Wilt claimed he'd been with 20,000 women. Nobody could confirm it. Nobody could deny it either.",
      "MJ's Hall of Fame speech was supposed to be grateful. Instead he called out every doubter. For 23 minutes."
    ].freeze,

    # ─── NBA Oddities & Bizarre History ──────────────────────────────────
    oddities: [
      "The NBA shot clock exists because a game once ended 19-18. The sport was literally dying.",
      "Jerry West won Finals MVP in 1969. His team lost the series. He was THAT good in a losing effort.",
      "Bubba Wells fouled out of an NBA game in 3 minutes. Three. That's barely enough time to tie your shoes.",
      "Before the shot clock, teams would just hold the ball for entire quarters. Fans paid money for that.",
      "The NBA used to do a jump ball after every single made basket. Every. Single. One.",
      "Manute Bol was 7'7\" and a center. He hit six three-pointers in one game. Nobody saw it coming.",
      "Michael Jordan was cut from his high school varsity team. As a sophomore. Let that origin story sit.",
      "The Harlem Globetrotters beat the Minneapolis Lakers in a real game in 1948. Not a show. A real game.",
      "The NBA's tallest player ever was Gheorghe Muresan at 7'7\". He then starred in a movie called My Giant.",
      "A 1979 Nets-Sixers game had 52 personal fouls. Both benches cleared. Basketball was violent back then.",
      "The longest NBA game ever went 6 overtimes. Indianapolis vs Rochester, 1951. Those men needed oxygen.",
      "Tim Duncan was a competitive swimmer. A hurricane destroyed his pool. The NBA got him by accident.",
      "The NBA banned jersey number 69. Why? Because Dennis Rodman tried to wear it. Of course he did.",
      "Muggsy Bogues was 5'3\". He blocked a Patrick Ewing shot. Five-foot-three blocked seven feet tall.",
      "The Celtics' famous parquet floor was made from scrap wood. Post-WWII shortages. Iconic by accident.",
      "Wilt Chamberlain never fouled out of a game. Not once. In 14 years. The man played 48.5 min a game.",
      "The NBA literally banned zone defense until 2001. You HAD to play man-to-man. It was the rule.",
      "Magic vs Bird started in the 1979 NCAA title game. The greatest rivalry in NBA history began in college.",
      "The Pacers once had a bus driver who was also listed as an emergency backup player. Budget era NBA.",
      "Shaq broke so many backboards the NBA had to reinforce every single hoop in the league. Because of one man.",
      "The 1998 lockout cut the season to 50 games. Shortest since the merger. MJ left anyway.",
      "Red Auerbach would light a cigar on the bench when he decided the game was over. While still playing.",
      "Jack Nicholson has been courtside at Lakers games since 1970. Over 50 years in the same seat.",
      "The NBA draft once had unlimited rounds. In 1960 it went 21 rounds deep. Everyone got drafted.",
      "The ABA played with a red, white, and blue ball. Looked ridiculous. But the NBA stole their 3-point line."
    ].freeze
  }.freeze

  ALL_FACTS = FACTS_BY_CATEGORY.values.flatten.freeze

  class << self
    def random
      ALL_FACTS.sample
    end

    def random_with_category
      category = FACTS_BY_CATEGORY.keys.sample
      fact = FACTS_BY_CATEGORY[category].sample
      reaction = REACTIONS[category].sample
      {
        emoji: CATEGORY_EMOJIS[category],
        category_name: CATEGORY_NAMES[category],
        fact: fact,
        reaction: reaction
      }
    end
  end
end
