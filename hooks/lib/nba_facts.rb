# frozen_string_literal: true

# NbaFacts - Categorized NBA and NBA Jam trivia for session startup
# 175+ curated facts across 6 categories, each capped at 120 characters

module NbaFacts
  CATEGORY_EMOJIS = {
    jam_arcade:    "\u{1F579}\uFE0F",
    jam_franchise: "\u{1F3AE}",
    jam_culture:   "\u{1F4B0}",
    iconic_moments: "\u{1F3C0}",
    player_quotes: "\u{1F4AC}",
    oddities:      "\u{1F92F}"
  }.freeze

  FACTS_BY_CATEGORY = {
    # ─── NBA Jam Arcade (1993 original) ──────────────────────────────────
    jam_arcade: [
      "NBA Jam creator Mark Turmell was a Pistons fan and secretly coded the Bulls to miss late shots.",
      "The original NBA Jam cabinet earned operators up to $2,400 per week in quarters.",
      "NBA Jam used digitized photos of real NBA players — heads were filmed on a rotating platform.",
      "Tim Kitzrow recorded \"BOOMSHAKALAKA\" in a single take during the original voice session.",
      "NBA Jam's AI used hidden rubber-banding — trailing teams got invisible stat boosts.",
      "You could play as Bill Clinton by entering a secret code at the matchup screen.",
      "Al Gore, Prince Charles, and Heavy D were hidden characters in the original arcade.",
      "NBA Jam tracked real NBA stats via modem updates sent to arcade cabinets weekly.",
      "The original arcade had no visible three-point line — long shots just counted as threes.",
      "NBA Jam was coded in assembly language to squeeze maximum performance from Midway's hardware.",
      "Developers played so many test games they could beat the AI without looking at the screen.",
      "Backboard-shattering dunks were added after testers complained normal dunks felt boring.",
      "NBA Jam's fire trail effect used only 4 animation frames to save precious ROM space.",
      "The goaltending rule was intentionally removed to make gameplay more explosive.",
      "Players catch fire after 3 consecutive baskets — a mechanic inspired by real hot streaks.",
      "NBA Jam's attract mode generated more coin drops than any sports game before it.",
      "Each NBA Jam cabinet shipped with a coin counter that Midway used for revenue tracking.",
      "The turbo meter was a last-minute addition that transformed the game's entire pacing.",
      "NBA Jam ran at 54 FPS on custom Midway hardware — unusually smooth for 1993 arcades.",
      "Mark Turmell hid a special code that made the Pistons virtually unbeatable at home.",
      "The game's scaling sprites made dunkers appear to fly 20 feet above the rim.",
      "NBA Jam's sound board held over 200 digitized voice clips from Tim Kitzrow.",
      "Midway tested NBA Jam at a single Chicago arcade before the nationwide rollout.",
      "The original code had a bug where player heads occasionally swapped mid-game.",
      "NBA Jam's two-on-two format was chosen because four full teams wouldn't fit in memory.",
      "Gary Payton's in-game speed rating was maxed out at 10, the highest of any player.",
      "Scottie Pippen appeared in NBA Jam but Michael Jordan did not — he had his own deal.",
      "NBA Jam was the first arcade game to feature real-time stat tracking between sessions.",
      "The shot clock was removed entirely to keep the arcade pace frantic and coin-friendly.",
      "Midway's playtesters discovered that 2-on-2 tested better than 3-on-3 for quarter play.",
      "NBA Jam's code contained hidden developer initials accessible via specific button combos.",
      "The game's collision detection was intentionally loose to allow spectacular block animations.",
      "NBA Jam generated more revenue in 1993 than any other arcade game in North America.",
      "Tim Kitzrow voiced over 300 unique lines across all versions of the original NBA Jam.",
      "The \"Is it the shoes?\" call was a direct reference to Nike's Mars Blackmon commercials."
    ].freeze,

    # ─── NBA Jam Franchise (sequels, ports, revivals) ────────────────────
    jam_franchise: [
      "Tournament Edition added a 3-player-per-team mode and a fatigue system.",
      "NBA Jam TE included over 40 hidden characters including Fresh Prince and DJ Jazzy Jeff.",
      "The SNES version of NBA Jam sold over 5 million copies worldwide.",
      "NBA Jam: On Fire Edition (2010) brought back Tim Kitzrow for all-new commentary.",
      "NBA Hangtime (1996) introduced create-a-player with custom attributes and heads.",
      "The Sega Genesis port of NBA Jam had slightly different rosters than the SNES version.",
      "NBA Jam Extreme (1996) attempted 3D graphics but was poorly received by fans.",
      "EA Sports revived NBA Jam in 2010 as a downloadable title for Xbox 360 and PS3.",
      "The Game Boy version of NBA Jam was surprisingly faithful despite the tiny screen.",
      "Tournament Edition's \"Hot Spots\" gave bonus points for shots from specific court zones.",
      "NBA Jam on Atari Jaguar was one of the few bright spots in the console's library.",
      "NBA Hangtime let you save custom players to the cabinet using a PIN code system.",
      "The 32X version of NBA Jam was considered one of the best console ports available.",
      "NBA Jam: On Fire Edition added \"Tag Mode\" letting you switch between all team players.",
      "Tournament Edition's injury system could knock your best player out for multiple quarters.",
      "The 3DO version featured full-motion video intros not seen in other console ports.",
      "NBA Jam TE's tournament mode tracked wins across multiple play sessions via passcodes.",
      "NBA Hangtime was the last NBA Jam-style game Midway released in arcades.",
      "EA's 2010 revival included a \"Remix Tour\" mode with power-ups and boss battles.",
      "The Game Gear port of NBA Jam ran at half the frame rate but kept all the voice clips.",
      "Tournament Edition fixed the original's Pistons bias — sort of. Turmell says he toned it down.",
      "NBA Jam TE added a \"Power-Up\" mode with icons that granted temporary abilities on court.",
      "The Saturn port of NBA Jam Tournament Edition was Japan-exclusive and extremely rare.",
      "NBA Jam's franchise has sold over 10 million copies across all platforms combined.",
      "On Fire Edition's online mode was the first time NBA Jam had competitive multiplayer over internet."
    ].freeze,

    # ─── NBA Jam Cultural Impact ─────────────────────────────────────────
    jam_culture: [
      "NBA Jam earned over $1 billion in quarters during its first year in arcades (1993).",
      "NBA Jam's first-year arcade revenue exceeded Jurassic Park's box office gross.",
      "\"BOOMSHAKALAKA\" became so iconic it appeared in dictionary slang references by 1995.",
      "NBA Jam's success spawned Midway's entire sports line: NFL Blitz, NHL Hitz, MLB Slugfest.",
      "Tim Kitzrow's commentary style directly influenced every arcade sports game that followed.",
      "Dennis' Place arcade in Chicago held the Guinness record for most NBA Jam cabinets (14).",
      "NBA Jam was referenced in over 30 TV shows and movies throughout the 1990s.",
      "The \"He's on fire!\" catchphrase was used in actual NBA broadcasts by commentators.",
      "NBA Jam introduced millions of non-basketball fans to the sport through arcades.",
      "Midway's stock price doubled in the year following NBA Jam's release.",
      "NBA Jam's success convinced the NBA to license its brand more aggressively to games.",
      "The game's over-the-top style influenced the NBA Street and AND1 Mixtape game series.",
      "\"From downtown!\" became standard basketball slang partly due to NBA Jam's popularity.",
      "NBA Jam merchandise — shirts, hats, posters — sold in malls nationwide through 1994.",
      "Multiple NBA players have cited NBA Jam as their childhood introduction to basketball.",
      "The game's cultural footprint led ESPN to produce a full documentary on its creation.",
      "NBA Jam's announcer calls are sampled in hundreds of hip-hop tracks from the 90s to today.",
      "Pizza Hut ran a national NBA Jam promotion offering game tokens with pizza purchases.",
      "NBA Jam was the first video game most Gen X kids played that used real athlete names.",
      "The \"Boom\" sound effect from NBA Jam dunks became a staple in 90s TV commercial editing."
    ].freeze,

    # ─── Iconic NBA Moments ──────────────────────────────────────────────
    iconic_moments: [
      "Wilt Chamberlain scored 100 points on March 2, 1962 — no TV broadcast exists.",
      "Michael Jordan's \"Last Shot\" over Bryon Russell sealed his 6th title in 1998.",
      "Magic Johnson announced his HIV diagnosis in 1991, then made the All-Star team months later.",
      "Larry Bird told opponents where he'd shoot from — then hit the shot anyway.",
      "The 1992 Dream Team outscored opponents by an average of 43.8 points in the Olympics.",
      "Kawhi Leonard's buzzer beater bounced 4 times on the rim before falling in Game 7 (2019).",
      "Damian Lillard hit a 37-foot three with 0.9 seconds left to eliminate OKC in 2019.",
      "Reggie Miller scored 8 points in 8.9 seconds against the Knicks in the 1995 playoffs.",
      "Allen Iverson stepped over Tyronn Lue after hitting a jumper in the 2001 Finals.",
      "Tim Duncan's bank shot from the wing in 2008 is considered the greatest near-miss ever.",
      "LeBron James chased down Andre Iguodala for a legendary block in the 2016 Finals Game 7.",
      "Michael Jordan switched hands mid-air on a layup against the Lakers in the 1991 Finals.",
      "Kobe Bryant scored 81 points against the Raptors on January 22, 2006.",
      "Russell Westbrook averaged a triple-double for three consecutive seasons (2017-2019).",
      "Stephen Curry hit 402 threes in 2015-16, shattering his own record by 116 makes.",
      "The Malice at the Palace (2004) led to the strictest fan conduct rules in NBA history.",
      "Hakeem Olajuwon's Dream Shake was so effective it inspired a generation of big men.",
      "Michael Jordan scored 63 points against the Celtics in the 1986 playoffs — a record.",
      "The 2016 Cavaliers came back from 3-1 down to beat the 73-win Warriors in the Finals.",
      "Dirk Nowitzki's one-legged fadeaway carried Dallas to an upset championship in 2011.",
      "Willis Reed limped onto the court for Game 7 in 1970 and inspired the Knicks to a title.",
      "Kareem Abdul-Jabbar's skyhook was so unstoppable no defender consistently blocked it.",
      "LeBron passed Kareem to become the NBA's all-time leading scorer in February 2023.",
      "Tracy McGrady scored 13 points in 35 seconds against the Spurs in 2004.",
      "Derek Fisher hit a buzzer beater with 0.4 seconds left against the Spurs in 2004.",
      "Bill Russell won 11 championships in 13 seasons — the most dominant run in sports history.",
      "Vince Carter's between-the-legs dunk in the 2000 Slam Dunk Contest redefined the event.",
      "The Celtics and Lakers have met in the Finals 12 times — the NBA's greatest rivalry.",
      "Dennis Rodman grabbed 34 rebounds in a single game while playing for the Pistons.",
      "Shaq missed 5,317 free throws in his career — more than most players ever attempt.",
      "Steph Curry's unanimous MVP in 2016 was the first in NBA history.",
      "The 1995-96 Bulls went 72-10, a record that stood for 20 years until the Warriors' 73-9.",
      "Isaiah Thomas scored 25 points in the 4th quarter of an elimination game on a bad ankle.",
      "Robert Horry hit more clutch playoff shots than almost any star — earning the name Big Shot Rob.",
      "Kevin Garnett's intensity was so legendary that teammates feared his pregame speeches.",
      "Ray Allen's corner three in Game 6 of the 2013 Finals saved the Heat's championship run.",
      "Devin Booker scored 70 points at age 20, making him the youngest to reach that mark.",
      "Luka Doncic hit a one-legged three-pointer at the buzzer in the 2020 playoff bubble.",
      "Giannis Antetokounmpo's 50-point Finals closeout game in 2021 was an all-time performance.",
      "Magic Johnson played center in Game 6 of the 1980 Finals as a rookie and dropped 42 points."
    ].freeze,

    # ─── Player Quotes ───────────────────────────────────────────────────
    player_quotes: [
      "Larry Bird at the 3-point contest: \"Who's coming in second?\"",
      "Allen Iverson: \"We talkin' about practice. Not a game. Practice.\" (2002 press conference)",
      "Antoine Walker on why he shoots threes: \"Because there are no fours.\"",
      "Rasheed Wallace popularized \"Ball don't lie\" after opponents missed free throws.",
      "Michael Jordan: \"I've failed over and over again in my life. That is why I succeed.\"",
      "Shaq on his free throws: \"I'm like the Pythagorean theorem — not easy to figure out.\"",
      "Kevin Garnett: \"Anything is possible!\" — screamed after winning his first title in 2008.",
      "Kobe Bryant: \"Job's not finished\" when asked how it felt to be up 2-0 in the Finals.",
      "LeBron James: \"I'm not going to sit here and say I'm a model citizen. I'm LeBron James.\"",
      "Charles Barkley: \"I am not a role model. Parents should be role models.\" (1993 Nike ad)",
      "Tim Duncan to a referee: \"Good call\" — then got a technical foul for being sarcastic.",
      "Steph Curry after beating the Celtics: \"What are they gonna say now?\"",
      "Russell Westbrook: \"I don't care what people say. I play for my teammates.\"",
      "James Harden: \"I'm the best player in the world. Why wouldn't I believe that?\"",
      "Draymond Green: \"They don't love you until you leave. I'm not leaving.\"",
      "Pat Riley coined \"Three-peat\" and actually trademarked the term in 1988.",
      "Kevin Durant tweeted from burner accounts defending himself against critics.",
      "Dennis Rodman once skipped practice to wrestle with Hulk Hogan on live TV.",
      "Shaq released 4 rap albums — his debut \"Shaq Diesel\" went platinum in 1993.",
      "Yogi Berra (not NBA, but quoted by every coach): \"It ain't over till it's over.\"",
      "Jimmy Butler: \"You f***ing need me\" — yelled at teammates during a Timberwolves practice.",
      "Bill Walton once called a play \"the greatest thing to happen since the invention of the wheel.\"",
      "Reggie Miller to Spike Lee after hitting a three: pointed and smiled, no words needed.",
      "Larry Bird played an entire game left-handed because he felt the Blazers weren't challenging.",
      "Gary Payton's trash talk was so relentless opponents requested not to guard him.",
      "Paul Pierce: \"I called game\" — after hitting a buzzer beater over the Hawks in 2015.",
      "Dirk Nowitzki: \"Shut it down. Let's go home!\" — after a playoff series clincher.",
      "Joel Embiid named himself \"The Process\" after the Sixers' controversial rebuild strategy.",
      "Wilt Chamberlain claimed to have scored with 20,000 women — a stat no one can verify.",
      "Michael Jordan's Hall of Fame speech was famously petty, calling out every perceived slight."
    ].freeze,

    # ─── NBA Oddities & Bizarre History ──────────────────────────────────
    oddities: [
      "The NBA shot clock was invented in 1954 after a game ended 19-18, nearly killing the sport.",
      "Jerry West won Finals MVP in 1969 despite his Lakers losing the series to the Celtics.",
      "Bubba Wells fouled out of an NBA game in just 3 minutes — an all-time record.",
      "Before the shot clock, teams would hold the ball for entire quarters to protect a lead.",
      "The NBA once used a jump ball after every made basket, not just to start each quarter.",
      "Manute Bol, at 7'7\", once hit six three-pointers in a game despite being a center.",
      "Michael Jordan was cut from his high school varsity team as a sophomore.",
      "The Harlem Globetrotters beat the Minneapolis Lakers in a real competitive game in 1948.",
      "The NBA's tallest player was Gheorghe Muresan at 7'7\" — he starred in the movie My Giant.",
      "A 1979 game between the Nets and 76ers had 52 personal fouls called — both benches cleared.",
      "The longest NBA game went 6 overtimes: Indianapolis Olympians vs Rochester Royals, 1951.",
      "Tim Duncan was a competitive swimmer before a hurricane destroyed his local pool.",
      "The NBA banned the specific jersey number 69 — Dennis Rodman tried to wear it.",
      "Muggsy Bogues at 5'3\" blocked a Patrick Ewing shot — the ultimate David vs Goliath.",
      "The original Celtics parquet floor was made from scrap wood due to post-WWII shortages.",
      "Wilt Chamberlain never fouled out of a single game in his entire 14-year career.",
      "The NBA had a rule banning zone defense until 2001 — man-to-man was mandatory.",
      "Magic Johnson and Larry Bird first played against each other in the 1979 NCAA title game.",
      "The Pacers once had a team bus driver who doubled as an emergency backup player.",
      "Shaq broke so many backboards the NBA reinforced every hoop in the league because of him.",
      "The 1998 lockout shortened the season to 50 games — the shortest since the merger.",
      "Red Auerbach would light a victory cigar on the bench when he felt a win was secured.",
      "Jack Nicholson has sat courtside at Lakers games since 1970 — over 50 years of fandom.",
      "The NBA draft once had unlimited rounds — in 1960, it went 21 rounds deep.",
      "The ABA used a red, white, and blue ball — the NBA adopted the three-point line from them."
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
      { emoji: CATEGORY_EMOJIS[category], fact: fact, category: category }
    end
  end
end
