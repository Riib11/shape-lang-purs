module Data.Words where

import Data.Array
import Data.String as String
import Prelude

import Data.Array.Unsafe (index')

words_4letter :: Array String 
words_4letter = String.split (String.Pattern " ") "abed abet able ably abut acai aced aces ache achy acid acme acne acre acts adds adit adze aeon afar afro agar aged ages agog ague ahem aide aids ails aims airs airy ajar akin alar alas ales alga ally alms aloe also alto alum ambo amen amid ammo amok amps amyl ands anew ankh anna anon anti ants apes apex apps apse aqua arch arcs area aria arid aril arks arms army arse arts arty arum aryl ashy asks atom atop aunt aura auto aver avid avow away awed awes awls awry axed axel axes axil axis axle axon baba babe baby bach back bade bads bags baht bail bait bake bald bale balk ball balm band bane bang bank bans barb bard bare barf bark barn bars base bash bask bass bast bath bats batt baud bawl bays bead beak beam bean bear beat beau beck beds beef been beep beer bees beet begs bell belt bend bent berg berm best beta bets bevy beys bias bibb bibs bide bids bier biff bike bile bilk bill bind bint bios bird bite bits blab blah bleb bled blew blip blob bloc blog blot blow blue blur boar boas boat bobs bode bods body bogs bogy boil bola bold bole boll bolo bolt bomb bond bone bong bonk bony boob book boom boon boor boos boot bore born boss both bots bout bowl bows boxy boyo boys bozo brad brag bran bras brat bray bred brew brie brig brim brio bris brit bros brow buck buds buff bugs bulb bulk bull bump bums bund bung bunk buns bunt buoy burb burg burl burn burp burr bury bush busk buss bust busy butt buys buzz byes byre byte cabs cads cafe caff cage cake calf call calm came cami camo camp cams cane cans cape capo caps carb card care carp carr cars cart case cash cask cast cats caul cava cave cavy caws cays cede cell cels celt cent cess chad chai chap char chat chef chew chic chin chip chit chop chow chub chug chum ciao cite city clad clam clan clap claw clay clef clip clod clog clop clot club clue coal coat coax cobs coca cock coco coda code cods coed cogs coho coif coil coin coir coke cola cold cole colt coma comb come comp cone conk conn cons cook cool coop coos coot cope cops copy cord core cork corm corn cosh cost cosy cote cots coup cove cowl cows cozy crab crag cram crap craw crew crib crit croc crop crow crud crus crux cube cubs cuds cued cues cuff cull culm cult cups curb curd cure curl curs curt cusp cuss cute cuts cyan cyst czar dabs dace dada dado dads daft dais dale dame damn damp dams dank dare dark darn dart dash data date daub dawn days daze dead deaf deal dean dear debt deck deed deem deep deer deft defy deke deli dell delt demo dens dent deny derm desk dews dewy dhal dhow dial dice died dies diet digs dike dill dime dims dine ding dink dino dint dips dire dirt disc dish disk diss diva dive dock docs dodo doer does doff doge dogs dojo dole doll dolt dome done dong doom door dope dork dorm dory dosa dose dote doth dots dour dove down doxy doze dozy drab drag dram draw dray drew drip drop drug drum drys dual dubs duck duct dude duds duel dues duet duff dugs duke dull duly dumb dump dune dung dunk duns duos dupe dura dusk dust duty dyad dyed dyer dyes dyke each earl earn ears ease east easy eats eave ebbs echo ecru eddy edge edgy edit eels eggs eggy egos ekes elan elks ells elms else emic emir emit emmy emus ends envy eons epee epic eras ergs errs eruv etas etch euro even ever eves evil ewer ewes exam exec exit exon expo eyed eyes fabs face fact fade fado fads fail fain fair fake fall fame fang fans fare farm faro fart fast fate fats faun fava fave fawn faze fear feat feck feed feel fees feet fell felt fend fens fern fess fest feta fete feud fiat fibs fief fife figs file fill film filo find fine fink fins fire firm firs fish fist fits five fizz flab flag flak flam flan flap flat flaw flax flay flea fled flee flew flex flip flit floc floe flog flop flow flub flue flus flux foal foam fobs foci foes fogs fogy foil fold folk fond font food fool foot fops ford fore fork form fort foul four fowl foxy frag frat fray free fret frig frog from fuel fugu full fume fund funk furl furs fury fuse fuss futz fuzz gaff gage gags gain gait gala gale gall gals game gams gang gaol gape gaps garb gash gasp gate gave gawk gawp gays gaze gear geek gees gels gelt gems gene gens gent genu germ geta gets ghat ghee gibe gift gigs gild gill gilt gimp gins gird girl girt gist gite gits give glad glam glee glen glia glib glob glom glop glow glue glug glum glut gnar gnat gnaw gnus goad goal goat gobs goby gods goer goes gold golf gone gong good goof gook goon goop goos gore gory gosh goth gout gown goys grab grad gram gran gray gree grew grey grid grim grin grip grit grog grow grub grue guar guff gulf gull gulp gums gunk guns guru gush gust guts guys gyms gyre gyro hack haft hags hail hair hajj hake half hall halo halt hams hand hang hank haps hard hare hark harm harp hart hash hasp hate hath hats haul have hawk haws hays haze hazy head heal heap hear heat heck heed heel heft heir held hell helm helo help heme hemp hems hens herb herd here hero hers hewn hews hick hide hied high hike hill hilt hind hint hips hire hiss hits hive hiya hoar hoax hobo hock hoed hoes hogs hold hole holo holt holy home hone hong honk hood hoof hook hoop hoot hope hops hora horn hose host hour hove howl hubs huck hued hues huff huge hugs hula hulk hull hump hums hung hunk hunt hurl hurt hush husk huts hymn hype hypo ibex ibis iced ices icky icon idea idle idly idol iffy ikat ikon ills imam imps inch info inks inky inns into ions iota iris irks iron isle isms itch item jabs jack jade jail jake jamb jams jape jars java jaws jays jazz jean jeep jeer jeez jefe jell jerk jest jets jibe jibs jigs jilt jink jinn jinx jive jobs jock joey jogs john join joke jolt josh jots jowl joys judo judy jugs juju juke jump junk jury just jute juts kaka kale kami kart kata kava keel keen keep kegs kelp kept kerb kerf keto keys khan khat kick kids kill kiln kilo kilt kind king kips kiss kite kith kits kiva kiwi knee knew knit knob knot know koan kohl koji kola kook kora koto kudu labs lace lack lacy lads lady lags laid lain lair lake lakh lama lamb lame lamp lams land lane laps lard lark lash lass last late lath lats laud lava lave lawn laws lays laze lazy lead leaf leak lean leap leas leek leer leet left legs leis lend lens lent less lest levy lewd leys liar libs lice lick lids lied lien lier lies lieu life lift like lilt lily lima limb lime limn limo limp line ling link lint lion lips lira lisp list lite live load loaf loam loan lobe lobs loch lock loco lode loft loge logo logs loin loll lone long look loom loon loop loos loot lope lops lord lore lose loss lost loth lots loud lout love lows luau lube luck luff luge lugs lull lump lune lung lure lurk lush lust lute luvs lynx lyre lyse mace mach mack macs made mage magi mags maid mail maim main make maki mako male mall malt mama mane mans many maps mare mark marl mars mart masa mash mask mass mast mate math mats maul maws maxi maya mayo maze mazy mead meal mean meat meek meet mega meld melt memo mend menu meow mere mesa mesh mess meta mete mewl mews meze mica mice mics mids mien mike mild mile milk mill mime mina mind mine mini mink mint minx mire miry mise miso miss mist mite mitt moan moat mobs mock mode mods mojo mola mold mole moll molt moms monk mono mood mook moon moor moos moot mope mops more morn mosh moss most mote moth move mows much muck muds muff mugs mule mull mums mung muon murk muse mush musk muss must mute mutt myth naan nabe nabs naff nags nail name nana nans napa nape naps narc nard nary nave navy nays neap near neat neck need neem nene neon nerd ness nest nets news newt next nibs nice nick nigh nine nips nite nobs nock node nods noel noir nome none nook noon nope nori norm nose nosh nosy note noun nous nova nubs nude nuke null numb nuns nuts oafs oaks oaky oars oath oats obey obit oboe odds odes odor ogee ogle ogre oils oily oink okay okra olds oldy oleo olla omen omit once ones only onto onus onyx oops ooze oozy opal open opts opus oral orbs orca ordo ores orgy oryx orzo otic otto ouch ours oust outs ouzo oval oven over ovum owed owes owls owns pace pack pact pads page paid pail pain pair pale pall palm palp pals pane pang pans pant papa paps para pare park pars part pass past pate path pats pave pawn paws pays peak peal pear peas peat peck pecs peds peed peek peel peep peer pees pegs pelt pens pent peon pepo peri perk perm perp pert perv peso pest pets pews phew phis pica pice pick pics pied pier pies pigs pika pike pile pill pimp pine ping pink pins pint pion pipa pipe pish piss pita pith pits pity pixy plan plat play plea pleb pled plex plod plop plot plow ploy plug plum plus pock pods poem poet poke poky pole poll polo pols poly pome pomp pond pone pong pony poof pool poop poor pope pops pore pork porn port pose posh post posy pots pouf pour pout poxy pram pray prep prey prez prig prim prob prod prof prog prom prop pros prow psis pubs puck puds puff pugs puja puke pull pulp puma pump punk puns punt puny pupa pups pure puri purl purr push puss puts putt putz pyre pyro quad quay quid quip quit quiz race rack racy rads raft raga rage rags raid rail rain raja rake raki raku rale rami ramp rams rang rank rant rape raps rapt rare rash rasp rate rath rats rave rays raze razz read real ream reap rear redo reed reef reek reel refs rein rely rems rend rent repo repp reps rest rete rhea ribs rice rich ride rids rife riff rift rigs rile rill rime rims rind ring rink riot ripe rips rise risk rite ritz road roam roan roar robe robs rock rode rods roes roil role roll romp roms rood roof rook room roos root rope ropy rose rosy rota rote roti roto rots rout roux rove rows rube rubs ruby ruck rude rued rues ruff rugs ruin rule rump rums rune rung runs runt ruse rush rust ruth ruts sack sacs safe saga sage sago sags said sail sake saki sale salt same sand sane sang sank saps sari sash sass sate sati save sawn saws says scab scad scam scan scar scat scot scow scud scum seal seam sear seas seat sect seed seek seem seen seep seer sees self sell semi send sent sept sere serf seta sets sett sewn sews sexy shad shag shah sham shed shew shim shin ship shit shiv shod shoe shoo shop shot show shul shun shut sibs sick side sift sigh sign sika silk sill silo silt sine sing sink sins sips sire sirs site sits size skeg skew skid skim skin skip skis skit skua slab slag slam slap slat slaw slay sled slew slid slim slip slit slob sloe slog slop slot slow slug slum slur smog smug smut snag snap snip snit snob snog snot snow snub snug soak soap soar soba sobs soca sock soda sods sofa soft soil sold sole solo soma some song sons soon soot sops sora sore sort sots souk soul soup sour sown sows soya spam span spar spas spat spay spaz spec sped spew spin spit spot spry spud spun spur stab stag star stat stay stem step stew stir stop stow stub stud stun stye subs such suck sued sues suet suit sulk sumo sump sums sung sunk suns sups sura sure surf suss swab swag swam swan swap swat sway swig swim swum sync tabs tabu tach tack taco tact tags tail take talc tale talk tall tame tamp tang tank tans tapa tape taps tare tarn taro tarp tars tart task taut taxa taxi teak teal team tear teas teat tech teem teen tees teff tele tell temp tend tent term tern test text than that thaw thee them then thew they thin this thou thro thru thud thug thus tian tick tics tide tidy tied tier ties tiff tiki tile till tilt time tine ting tins tint tiny tipi tips tire toad toby toed toes toff tofu toga toil toke told tole toll tomb tome tone tong tony took tool toon toot topi topo tops torc tore torn torr tort tory toss tote tots tour tout town tows toys tram trap tray tree trek trey trig trim trio trip trod trot tsar tuba tube tubs tuck tufa tuff tuft tugs tule tums tuna tune turd turf turk turn tush tusk tuts tutu twee twig twin twit twos tyke type typo tyre tyro udon ugly ulna umma umps undo unit unto updo upon urea urge uric urns used user uses vacs vail vain vale vamp vane vans vary vasa vase vast vats veal veep veer vees veil vein veld vena vend vent verb vert very vest veto vets vial vibe vice vids vied vies view vile vill vims vine vino viol visa vise vita viva void vole volt vote vows wack wade wadi wads waft wage wags waif wail wait wake wale wali walk wall wand wane wans want ward ware warm warn warp wars wart wary wash wasp wast watt wave wavy waxy ways weak weal wean wear webs weds weed week weel ween weep wees weft well went were west what when whom wide wife wild will wind wine wing wins wipe wire wise wish with woke wolf wood wool word wore work worm worn wrap yard yarn yeah year yoga your zero zinc zone zoom"

getword_4letter :: Int -> String
getword_4letter i = index' words_4letter $ i `mod` (length words_4letter)