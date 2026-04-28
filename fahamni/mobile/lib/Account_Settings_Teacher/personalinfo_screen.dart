import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fahamni/models/user_model.dart';

// ── Wilaya → Communes map (same as registration) ─────────────────────────────
const Map<String, List<String>> _wilayaBaladiyat = {
  'Adrar': ['Adrar','Aougrout','Aoulef','Bouda','Fenoughil','In Zghmir','Ouled Ahmed Tammi','Reggane','Sali','Sebaa','Talmine','Tamest','Timiaouine','Tit','Tsabit','Zaouiet Kounta'],
  'Aïn Defla': ['Aïn Defla','Aïn Benian','Aïn Bouyahia','Aïn Torki','Aïn Lechiakh','Bathia','Belassaa Bouzegza','Boumedfaâ','Bourached','Djebala','Djelida','El Amra','El Attaf','El Maine','Hassania','Khemis Miliana','Mekhatria','Miliana','Oued Chorfa','Oued Djemaa','Rouina','Sidi Lakhdar','Tachta Zegagha','Tarik Ibn Ziad','Tiberkanine','Zeddine'],
  'Aïn Témouchent': ['Aïn Témouchent','Aïn Kihal','Aïn Tolba','Aoubellil','Beni Saf','Bouzedjar','El Amria','El Emir Abdelkader','El Malah','Hammam Bou Hadjar','Hassasna','Oued Berkeche','Oued Sabah','Sidi Ben Adda','Sidi Boumedienne','Sidi Safi','Tamzoura','Terga','Tousmouline'],
  'Algiers': ['Alger Centre','Sidi M\'hamed','Bab El Oued','Bologhine','Casbah','Oued Koriche','Bir Mourad Raïs','El Biar','Bouzareah','Ben Aknoun','Dely Ibrahim','El Madania','Hussein Dey','Kouba','Mohammadia','Bachdjerrah','Bourouba','El Harrach','Baraki','Oued Semar','Dar El Beïda','Bab Ezzouar','Beni Messous','Aïn Bénian','Chéraga','Draria','Douéra','Zéralda','Staoueli','Rouïba','Réghaïa','Bordj El Bahri','Aïn Taya','Haraoua','Souidania','Mahelma','Rahmania','Ouled Chebel','El Achour','Ouled Fayet'],
  'Annaba': ['Annaba','Aïn Berda','Berrahal','Bounamoussa','Cheurfa','El Bouni','El Hadjar','Seraïdi','Sidi Amar','Treat'],
  'Batna': ['Batna','Aïn Djasser','Aïn Touta','Aïn Yagout','Arris','Barika','Bitam','Boumia','Bouzina','Chemora','Chir','Djezzar','El Madher','Fesdis','Foum Toub','Ghassira','Gueigoune','Ichmoul','Ichemoul','Inoughissen','Kais','Larbâa','Lazrou','Maafa','Menaa','Merouana','NGaous','Oued Chaaba','Ouled Fadel','Ouled Si Slimane','Ouled Ammar','Ouled Aouf','Ouled Sellam','Ras El Aioun','Seggana','Seriana','TKout','Tazoult','Taxlent','Teniet El Abed','Timgad','Toulmout','Zanat El Beïda'],
  'Béchar': ['Béchar','Abadla','Beni Ounif','Boukaïs','El Ouata','Igli','Kenadsa','Lahmar','Meridja','Mogheul','Taghit','Timoudi'],
  'Béjaïa': ['Béjaïa','Adekar','Aït R\'zine','Aït Smaïl','Akbou','Allaghène','Amalou','Aokas','Barbacha','Beni Djellil','Beni Ksila','Beni Maouche','Bouhamza','Boukhelifa','Chellata','Darguina','Draâ El Caïd','Feraoun','Ighram','Kendira','Kherrata','M\'Cisna','Melbou','Oued Ghir','Ouzellaguen','Seddouk','Semaoun','Sidi Aïch','Sidi Ayad','Souk El Thenine','Souk Oufella','Taskriout','Tazmalt','Timezrit','Tichy','Tinabdher','Tizi N\'Berber','Toudja'],
  'Biskra': ['Biskra','Aïn Naga','Aïn Zaatout','Bouchagroune','Branis','Chetma','Djemorah','El Feidh','El Ghrous','El Hadjeb','El Kantara','El Mizaraa','Foughala','Lichana','Lioua','M\'Chouneche','Mekhadma','Ouled Djellal','Oumache','Sidi Khaled','Sidi Okba','Tolga','Zeribet El Oued'],
  'Blida': ['Blida','Aïn Romana','Beni Mered','Beni Tamou','Bouarfa','Boufarik','Bougara','Bouinan','Chiffa','Chréa','Djebabra','El Affroun','Guérou','Hammam Melouane','Meftah','Mouzaïa','Oued Alleug','Oued Djer','Sidi Moussa','Sidi Naamane','Souhane'],
  'Bordj Bou Arréridj': ['Bordj Bou Arréridj','Aïn Taghrout','Aïn Tesra','Belimour','Beni Ouar','Bordj Ghedir','Bordj Zemmoura','Colla','Djaâfra','El Achir','El Eulma','El Hamadia','El Main','El M\'hir','Ghailassa','Haraza','Hasnaoua','Khelil','Mansoura','Medjana','Ouled Brahem','Ouled Dahmane','Ouled Sidi Brahim','Rabta','Ras El Oued','Sidi Embarek','Tafreg','Taglait','Teniet En Nasr','Tixter','Yellas'],
  'Bouira': ['Bouira','Aïn Bessam','Aïn El Hadjar','Aïn Laloui','Aïn Turk','Aït Laaziz','Bechloul','Bir Ghbalou','Bordj Okhriss','Boukram','Chorfa','Dechmia','Dirrah','Djebahia','El Asnam','El Hakimia','El Hachimia','El Kseur','Haizer','Hanif','Kadiria','Lakhdaria','Maamora','M\'Chedallah','Mezdour','Oued El Berdi','Oued El Kébir','Raouraoua','Ridane','Saharij','Souk El Khemis','Sour El Ghozlane','Taghzout','Zbarbar'],
  'Boumerdès': ['Boumerdès','Afir','Ammal','Baghlia','Beni Amrane','Boudouaou','Boudouaou El Bahri','Bouzegza Keddara','Chabet El Ameur','Corso','Dellys','Djinet','El Kharrouba','Isser','Khemis El Khechna','Larbatache','Legata','Naciria','Ouled Aïssa','Ouled Hedadj','Ouled Moussa','Si Mustapha','Sidi Daoud','Souk El Had','Taourga','Thenia','Tidjelabine','Timezrit','Zemmouri'],
  'Chlef': ['Chlef','Aïn Merane','Aïn Oussera','Beni Bouateb','Boukadir','Bouzeghaia','Breira','Chettia','Dahra','El Hadjadj','El Karimia','El Marsa','Harchoun','Labiod Medjadja','Moussadek','Oued Fodda','Oued Goussine','Oued Sly','Ouled Abbes','Ouled Ben Abdelkader','Oum Drou','Sendjas','Sidi Abderrahmane','Sidi Akkacha','Sobha','Tadjena','Talassa','Taougrite','Ténès','Zeboudja'],
  'Constantine': ['Constantine','Aïn Abid','Aïn Smara','Beni Hamidane','Didouche Mourad','El Khroub','Hamma Bouziane','Ibn Ziad','Oued Hamimime','Zighoud Youcef'],
  'Djelfa': ['Djelfa','Aïn Chouhada','Aïn El Ibel','Aïn Fekka','Aïn Maabed','Aïn Oussera','Amourah','Benhar','Beni Yagoub','Bouira Lahdab','Charef','Dar Chouikh','Delduol','El Guedid','El Idrissia','El Khemis','Faïdh El Botma','Guernini','Guettara','Had Sahary','Hassi Bahbah','M\'Liliha','Messaâd','Moudjebara','Oum Laadham','Sedd Rahal','Selmana','Sidi Baizid','Sidi Ladjel','Zaafrane','Zaccar'],
  'El Bayadh': ['El Bayadh','Arbaouat','Boualem','Bougtoub','Boussemghoun','Brezina','Cheguig','Chellala','El Abiodh Sidi Cheikh','El Bnoud','El Houita','Kef El Ahmar','Krakda','Mékeri','Rogassa','Sidi Ameur','Sidi Slimane','Sidi Tifour','Stitten','Tousmouline'],
  'El Oued': ['El Oued','Bayadha','Debila','Djamaa','El M\'Ghair','Guemar','Hassi Khalifa','Kouinine','Magrane','Mih Ouensa','Nakhla','Oued El Alenda','Ourmas','Reguiba','Robbah','Sidi Aoun','Taghzout','Tendla','Trifaoui'],
  'El Tarf': ['El Tarf','Aïn El Assel','Aïn Kerma','Asfour','Ben M\'Hidi','Berkhouche','Bouhadjar','Bouteldja','Chebaita Mokhtar','Cheffia','Dréan','Echatt','El Aioun','El Kala','Lac des Oiseaux','Oued Zitoun','Raml Souk','Souarekh','Zerizer'],
  'Ghardaïa': ['Ghardaïa','Bounoura','Dhayet Bendhahoua','El Atteuf','El Guerrara','Mansoura','Metlili','Sebseb','Zelfana'],
  'Guelma': ['Guelma','Aïn Ben Beida','Aïn Hessania','Aïn Larbi','Aïn Makhlouf','Aïn Reggada','Aïn Sandel','Belkheir','Ben Djerrah','Beni Mezline','Bordj Sabat','Bouati Mahmoud','Bouchegouf','Bouhamdane','Boumaâdja','Dahouara','Djeballah Khemissi','El Fedjoudj','Guelaat Bou Sbaâ','Hammam Debagh','Hammam N\'Bails','Héliopolis','Houari Boumediene','Khezaras','Medjez Amar','Medjez Sfa','Nechemata','Oued Cheham','Oued Fragha','Oued Zenati','Ras El Agba','Roknia','Salaoua Announa','Tamlouka'],
  'Jijel': ['Jijel','Boudriaa Ben Yadjis','Bouragba','Boussif Ouled Askeur','Chekfa','Djemaa Beni Habibi','Djimla','El Ancer','El Aouana','El Kennar Nouchfi','Emir Abdelkader','Erraguene','Ghebala','Kemir Oued Adjoul','Kheïri Oued Adjoul','Ouled Amar','Ouled Rabah','Ouled Yahia Khedrouche','Selma Benziada','Sidi Abdelaziz','Sidi Maarouf','Taher','Texenna','Ziama Mansouriah'],
  'Khenchela': ['Khenchela','Aïn Touila','Babar','Baghai','Bouhmama','Chechar','Cheria','Djellal','El Hamma','El Mahmal','Ensigha','Kais','Khirane','M\'Sara','MToussa','Ouled Rechache','Remila','Tamza','Yabous'],
  'Laghouat': ['Laghouat','Aïn Madhi','Aïn Sidi Ali','Beidha','Bennasser Benchohra','Brida','El Assafia','El Ghicha','Gueltat Sidi Saâd','Hadj Mechri','Hassi Delaa','Hassi R\'Mel','Kheneg','Ksar El Hirane','M\'Kham','Oued Morra','Oued M\'Zi','Sebgag','Sidi Bouzid','Sidi Makhlouf','Taouiala','Tadjemout','Tadjrouna','Tayebet','Tighremet','Touila'],
  'Mascara': ['Mascara','Aïn Fares','Aïn Fekan','Aïn Ferah','Aïn Frass','Alaimia','Benaïa','Bou Hanifia','Bou Henni','Chorfa','El Bordj','El Gaada','El Guettana','El Hachem','El Keurt','El Mamounia','Ghriss','Hachem','Khalouia','Macta','Mamounia','Matemore','Mocta Douz','Mohammadia','Nesmoth','Oggaz','Oued El Abtal','Oued Taria','Ras El Aïn Amirouche','Sedjerara','Sehailia','Sidi Abdeldjebar','Sidi Kada','Sidi Boussaid','Sig','Teghennif','Tizi','Zahana','Zelmata'],
  'Médéa': ['Médéa','Aïn Boucif','Aïn Ouksir','Aïn Benian','Aïn Bouziane','Aïn El Hadjar','Aïn El Kerma','Aïn Torki','Aziz','Baata','Ben Chicao','Belaas','Beni Slimane','Berrouaghia','Bir Ben Laabed','Boghar','Bou Aiche','Bouaichoune','Bouchrahil','Bouzeguene','Bouskene','Chellalet El Adhaoura','Cheniguel','Derrag','Djouab','Draa Essamar','El Azizia','El Guelb El Kebir','El Hamdania','El Hassania','El Omaria','Ferme','Hannacha','Ksar El Boukhari','Meghraoua','Mellab','Mihoub','Ouled Antar','Ouled Brahim','Ouled Deide','Ouled Hellal','Ouled Maaref','Ouled Ziane','Ouzera','Rebahia','Saneg','Sedraya','Seghouane','Si Mahdjoub','Sidi Damed','Sidi Naamane','Sidi Rabiâ','Sidi Zahar','Sidi Ziane','Souagui','Tablat','Tafraout','Tamesguida','Tizi Mahdi','Tletat Ed Douair','Zoubiria'],
  'Mila': ['Mila','Aïn Beida','Aïn El Kebira','Aïn Mellouk','Aïn Tine','Aïn El Khercha','Amira Arrès','Benyahia Abderrahmane','Bouhatem','Chelghoum Laïd','Chigara','Derradji Bousselah','El Mechira','Elayadi Barbès','Ferdjioua','Grarem Gouga','Hamala','M\'chira','Oued Athmania','Oued Endja','Oued Seguen','Rouached','Sidi Khelifa','Sidi Mérouane','Tadjenanet','Tassadane Haddada','Teleghma','Terrai Bainen','Tiberguent','Yahia Beni Guecha','Zerzara'],
  'Mostaganem': ['Mostaganem','Aïn Boudinar','Aïn Nouïssy','Aïn Sidi Cherif','Aïn Tedles','Belaâssel','Bouguirat','El Achour','El Hassiane','Fornaka','Hadjadj','Hassi Mameche','Khayr Eddine','Mansourah','Mazagran','Mesra','Nekmaria','Oued El Kheir','Ouled Boughalem','Ouled Maallah','Safsaf','Sayada','Sidi Ali','Sidi Belattar','Sidi Lakhdar','Sirat','Souaflia','Stidia','Tazgait','Touahria'],
  'M\'Sila': ['M\'Sila','Aïn El Hadjel','Aïn El Melh','Aïn Errich','Aïn Fares','Aïn Khadra','Belaiba','Ben Srour','Beni Ilmane','Benzouh','Bir Foda','Bou Saâda','Bouti Sayeh','Chellal','Dehahna','Djebel Messaâd','El Hamel','El Houamed','El M\'Chir','El Ouldja','Hammam Dhalaâ','Khettouti Sed El Djir','Maâdid','Magra','M\'Cif','Mohammed Boudiaf','Ouanougha','Oued Chair','Ouled Addi Guebala','Ouled Atia','Ouled Derradj','Ouled Madhi','Ouled Mansour','Ouled Sidi Brahim','Oultem','Ras El Ma','Sidi Aïssa','Sidi Hadjeres','Sidi M\'Hamed','Slim','Souamaa','Tamsa','Tarmount','Zarzour'],
  'Naâma': ['Naâma','Aïn Ben Khelil','Aïn Sefra','Asla','Djeniane Bourzeg','El Biod','Kasdir','Mécheria','Moghrar','Tiout'],
  'Oran': ['Oran','Aïn El Bia','Aïn El Kerma','Aïn El Turk','Arzew','Ben Freha','Benyamin','Birkhadem','Boufatis','Bouznika','El Ançor','El Kerma','El Hassi','Es Senia','Gdyel','Hassi Ben Okba','Hassi Bounif','Hassi Mefsoukh','Marsat El Hadjadj','Mers El Kébir','Misserghin','Oued Tlelat','Sidi Ben Yebka','Sidi Chami','Tafraoui'],
  'Ouargla': ['Ouargla','Aïn Beïda','Balidat Ameur','Benaceur','El Allia','El Borma','El Hadjira','Hassi Ben Abdellah','Hassi Messaoud','Megarine','NGoussa','Rouissat','Sidi Khouiled','Tebesbest','Touggourt'],
  'Oum El Bouaghi': ['Oum El Bouaghi','Aïn Babouche','Aïn Beïda','Aïn Diss','Aïn Fakroun','Aïn Kercha','Aïn M\'Lila','Aïn Zitoun','Behir Chergui','Berriche','Bir Chouhada','Dharmia','El Amiria','El Belala','El Fedjoudj Boughrara','El Harmilia','Fkirina','Hanchir Toumghani','Ksar Sbahi','Meskiana','Oued Nini','Ouled Gacem','Ouled Hamla','Ouled Zouaï','Rahia','Sidi Khelifa','Sidi Rached','Souk Naamane','Zorg'],
  'Relizane': ['Relizane','Aïn Rahma','Aïn Tarek','Ammi Moussa','Belaassel Bouzegza','Beni Dergoun','Beni Zentis','Dar Ben Abdellah','Djidioua','El Guettar','El Hamadna','El Hassi','El Matmar','El Ouldja','Hadjout','Kalaa','Lahlef','Mazouna','Mediouna','Mendes','Merdja Sidi Abed','Oued El Djemaa','Oued Rhiou','Ouled Aïch','Ouled Sidi Mihoub','Ramka','Sidi Khettab','Sidi Lazreg','Sidi M\'Hamed Ben Ali','Sidi Saâda','Sougueur','Yellel','Zemmoura'],
  'Saïda': ['Saïda','Aïn El Hadjar','Aïn Soltane','Doui Thabet','El Hassasna','Hounet','Moulay Larbi','Ouled Brahim','Ouled Khaled','Sidi Ahmed','Sidi Boubekeur','Sidi Amar','Tircine','Youb'],
  'Sétif': ['Sétif','Aïn Abessa','Aïn Arnat','Aïn Azel','Aïn El Kebira','Aïn Oulmène','Aïn Legraj','Aïn Roua','Aïn Sebt','Aïn Taguine','Amoucha','Babor','Beidha Bordj','Beni Aziz','Beni Chebana','Beni Fouda','Beni Hocine','Beni Mouhli','Bir El Arch','Bouandas','Bougaâ','Bousselam','Boutaleb','Dehamcha','Djemila','Draâ Kebila','El Eulma','El Ouldja','El Ouricia','Guelal','Guidjel','Hamma','Harbil','Ksar El Abtal','Maaouia','Mezloug','Oued El Barad','Ouled Addouane','Ouled Sabor','Ouled Teben','Ouled Si Ahmed','Rasfa','Salah Bey','Serdj El Ghoul','Tachouda','Talaifacene','Taya','Tella','Tizi N\'Bechar'],
  'Sidi Bel Abbès': ['Sidi Bel Abbès','Aïn Adden','Aïn El Berd','Aïn Kada','Aïn Thrid','Aïn Tindamine','Amarnas','Badredine El Mokrani','Belaâba','Benachiba Chelia','Benali Benyoub','Boubekeur','Bouhanche','Boukhanafis','Chebaita Mokhtar','Chettouane Belaila','Dhaya','El Haçaiba','Hassi Dahou','Hassi Zehana','Lamtar','Makedra','Marhoum','Mazzer','Mezaourou','Moulay Slissen','Oued Sebaa','Oued Sefioun','Ras El Ma','Redjem Demouche','Sfissef','Sidi Ali Benyoub','Sidi Brahim','Sidi Chaïb','Sidi Hamadouche','Sidi Khaled','Sidi Lahcene','Sidi Yacoub','Tabia','Talassa','Taoudmout','Teghalimet','Telagh','Tenira','Tessala','Tilmouni','Zerouala'],
  'Skikda': ['Skikda','Aïn Bouziane','Aïn Charchar','Aïn Kechra','Aïn Zouit','Azzaba','Bekkouche Lakhdar','Ben Azzouz','Beni Bechir','Beni Oulbane','Bin El Ouiden','Bouchtata','Cheraia','El Ghedir','El Hadaiek','El Marsa','Emdjez Edchich','Es Sebt','Filfila','Hamadi Krouma','Kanoua','Kerkera','Oued Djebbara','Ouled Attia','Ouled Hbaba','Oum Toub','Ramdane Djamel','Salah Bouchaour','Sidi Mezghiche','Tamalous','Zerdazas','Zitouna'],
  'Souk Ahras': ['Souk Ahras','Aïn Soltane','Aïn Zana','Bir Bouhouche','Drea','Haddada','Hanancha','Khedara','Khemissa','M\'Daourouch','Machroha','Merahna','Ouled Driss','Oum El Adhaïm','Ragouba','Saïda','Sedrata','Sidi Fredj','Sidi Hamla','Taoura','Terraguelt','Tiffech','Zaarouria','Zouabi'],
  'Tamanrasset': ['Tamanrasset','Abalessa','Idles','In Amguel','In Ghar','In Guezzam','Tazrouk','Tin Zaouatine'],
  'Tébessa': ['Tébessa','Aïn Zerga','Bekkaria','Bir El Ater','Bir Mokkadem','Boukhroufa','Boulhaf Dir','Cheria','El Aouinet','El Hammamet','El Kouif','El Ma El Abiod','El Meridj','El Ogla','El Ogla El Malha','Ferkane','Guorriguer','Hammamet','Morsott','Negrine','Oued Kabrit','Oum Ali','Safsaf El Ouesra','Stah Guentis','Tlidjene'],
  'Tiaret': ['Tiaret','Aïn Bouchekif','Aïn Deheb','Aïn Dzarit','Aïn El Hadid','Aïn Kermes','Aïn Zarit','Bougara','Chehaima','Dahmouni','Djebilet Rosfa','Djillali Ben Amar','Faidja','Frenda','Guertoufa','Hamadia','Ksar Chellala','Mechraâ Safa','Madna','Mahdia','Mechrouha','Medrissa','Mellakou','Nadorah','Oued Lilli','Rahouia','Rechaïga','Sebaïne','Sidi Abdelghani','Sidi Ali Mellal','Sidi Bakhti','Sidi Hosni','Sidi M\'Hamed','Sidi Mokhtar','Sidi Slimane','Sougueur','Tagdemt','Takhemaret','Tidda','Tousnina','Zmalet El Emir Abdelkader'],
  'Tipaza': ['Tipaza','Aïn Tagourait','Attatba','Beni Milleuk','Bou Ismail','Bouharoun','Bourkika','Chaiba','Cherchell','Damous','Douaouda','Fouka','Gouraya','Hadjout','Khemisti','Larhat','Menaceur','Merad','Messelmoun','Nador','Sidi Amar','Sidi Ghiles','Sidi Rached','Sidi Semiane','Tazgait','Tefessour'],
  'Tissemsilt': ['Tissemsilt','Aïn El Hadid','Aïn Larbi','Aïn Sefra','Beni Chaïb','Beni Lahcene','Bordj Bounaama','Bordj El Emir Abdelkader','Boucaïd','Boumaâd','Bouzeri','El Guerrouj','Khemisti','Lardjem','Layoune','Mâacem','Melaab','Ouled Bessem','Sidi Abed','Sidi Boutouchent','Sidi Lantri','Sidi Slimane','Tamalaht','Theniet El Had'],
  'Tizi Ouzou': ['Tizi Ouzou','Aïn El Hammam','Aghribs','Aït Aouggacha','Aït Bouaddou','Aït Boumahdi','Aït Chafâa','Aït Khellili','Aït Mahmoud','Aït Oumalou','Aït Yahia','Aït Yahia Moussa','Aït Ziki','Akbil','Assi Youcef','Azazga','Azeffoun','Béni Douala','Béni Yenni','Beni Ziki','Beni Zmenzer','Boghni','Boudjima','Bouzeguène','Draâ Ben Khedda','Draâ El Mizan','Fréha','Ibdouchene','Idjeur','Iferhounène','Ifigha','Iflissen','Illoula Oumalou','Imsouhel','Irdjen','Larbaâ Nath Irathen','Mâatkas','Makouda','Mekla','Mizrana','Ouacifs','Ouadhia','Oued Sebt','Oued Zeguir','Sidi Naâmane','Souamaâ','Souk El Thenine','Tadmaït','Tifra','Tighzirt','Timizart','Tirmitine','Tizi Gheniff','Tizi N\'Tleta','Tizi Rached','Yakouren','Yatafen','Zekri'],
  'Tlemcen': ['Tlemcen','Aïn Fetah','Aïn Fezza','Aïn Ghoraba','Aïn Kebira','Aïn Nehala','Aïn Tallout','Aïn Youcef','Amieur','Azails','Bab El Assa','Beni Bahdel','Beni Boussaid','Beni Khellad','Beni Mester','Beni Ouarsous','Beni Semiel','Bensekrane','Bouhlou','Chetouane','Dar Yaghmouracene','Djebala','El Aricha','El Bouihi','El Fehoul','El Gor','Fellaoucene','Ghazaouet','Hammam Boughrara','Hennaya','Honaïne','Maghnia','Mansourah','Marsa Ben M\'Hidi','Msirda Fouaga','Nedroma','Oued Lakhdar','Ouled Mimoun','Ouled Riyah','Remchi','Sabra','Sebbaa Chioukh','Sebdou','Sidi Abdelli','Sidi Djilali','Sidi Medjahed','Sidi Senoussi','Sidi Soufi','Souk Tlata','Terny Beni Hediel','Tianet','Zenata'],
};

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _descController      = TextEditingController();

  File?     _image;
  DateTime? _birthday;
  String?   _currentPictureUrl;
  String?   _uid;
  String?   _email;
  String?   _phone;
  Gender?   _gender;

  // Location
  String? _selectedCity;
  String? _selectedCommune;

  // Originals
  String?   _origFirstName;
  String?   _origLastName;
  String?   _origCity;
  String?   _origCommune;
  DateTime? _origBirthday;
  String?   _origDesc;

  bool    _isLoading = true;
  bool    _isSaving  = false;
  String? _errorMessage;

  bool get _isDirty =>
      _image != null ||
      _firstNameController.text.trim() != (_origFirstName ?? '') ||
      _lastNameController.text.trim()  != (_origLastName  ?? '') ||
      _descController.text.trim()      != (_origDesc      ?? '') ||
      _selectedCity    != _origCity    ||
      _selectedCommune != _origCommune ||
      (_birthday != null && _origBirthday != null &&
          (_birthday!.day   != _origBirthday!.day   ||
           _birthday!.month != _origBirthday!.month ||
           _birthday!.year  != _origBirthday!.year));

  List<String> get _communes =>
      _selectedCity != null ? (_wilayaBaladiyat[_selectedCity] ?? []) : [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      _uid = user.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      final role = UserRole.values.firstWhere(
        (r) => r.name == (userDoc['role'] ?? 'student'),
        orElse: () => UserRole.student,
      );

      final doc = await FirebaseFirestore.instance
          .collection(_collectionForRole(role)).doc(_uid).get();
      final data = doc.data()!;

      // Parse location "Commune, City"
      final loc = data['location'] ?? '';
      String parsedCity    = '';
      String parsedCommune = '';
      if (loc.contains(',')) {
        parsedCommune = loc.split(',').first.trim();
        parsedCity    = loc.split(',').last.trim();
      } else {
        parsedCity = loc;
      }

      setState(() {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text  = data['last_name']  ?? '';
        _email                    = data['email']       ?? '';
        _phone                    = data['phone']       ?? '';
        _currentPictureUrl        = data['picture'];
        _gender = Gender.values.byName(data['gender'] ?? 'male');
        _birthday = data['birthday'] != null
            ? (data['birthday'] as Timestamp).toDate()
            : null;

        _selectedCity    = _wilayaBaladiyat.containsKey(parsedCity) ? parsedCity : null;
        _selectedCommune = parsedCommune.isNotEmpty ? parsedCommune : null;

        _descController.text = data['pedagogical_description'] ?? '';

        _origFirstName = _firstNameController.text;
        _origLastName  = _lastNameController.text;
        _origDesc      = _descController.text;
        _origCity      = _selectedCity;
        _origCommune   = _selectedCommune;
        _origBirthday  = _birthday;
      });

      _firstNameController.addListener(() => setState(() {}));
      _lastNameController.addListener(()  => setState(() {}));
      _descController.addListener(()      => setState(() {}));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student: return 'students';
      case UserRole.tutor:   return 'tutors';
      case UserRole.parent:  return 'parents';
    }
  }

  ImageProvider _resolveAvatar() {
    if (_image != null) return FileImage(_image!);
    final pic = _currentPictureUrl;
    if (pic != null && pic.startsWith('http'))    return NetworkImage(pic);
    if (pic != null && pic.startsWith('assets/')) return AssetImage(pic);
    return _gender == Gender.female
        ? const AssetImage("assets/images/studentfemale.png")
        : const AssetImage("assets/images/studentmale.png");
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF000080))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (_uid == null) return;
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = 'First and last name are required.');
      return;
    }

    final location = (_selectedCommune != null && _selectedCity != null)
        ? '$_selectedCommune, $_selectedCity'
        : (_selectedCity ?? '');

    setState(() { _isSaving = true; _errorMessage = null; });

    try {
      String? pictureUrl = _currentPictureUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref().child('profile_pictures/$_uid.jpg');
        await ref.putFile(_image!);
        pictureUrl = await ref.getDownloadURL();
        _currentPictureUrl = pictureUrl;
      }

      final Map<String, dynamic> updates = {
        'first_name':               firstName,
        'last_name':                lastName,
        'location':                 location,
        'birthday':                 Timestamp.fromDate(_birthday ?? DateTime(2000)),
        'pedagogical_description':  _descController.text.trim(),
        'picture':                  pictureUrl ?? _currentPictureUrl ?? '',
      };

      await FirebaseFirestore.instance
          .collection('tutors')
          .doc(_uid)
          .update(updates);

      setState(() {
        _origFirstName = firstName;
        _origLastName  = lastName;
        _origDesc      = _descController.text.trim();
        _origCity      = _selectedCity;
        _origCommune   = _selectedCommune;
        _origBirthday  = _birthday;
        _image         = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF000080),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: _isDirty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 13,
                              fontFamily: "Inter"),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF000080),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text(
                                "Confirm Changes",
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Personal Info",
          style: TextStyle(
            fontFamily: 'Inter', fontSize: 32,
            fontWeight: FontWeight.w700, color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF000080)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Avatar ───────────────────────────────────────────
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _resolveAvatar(),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF000080), shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: const Text("Change Photo",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: Color(0xFF000080))),
                    ),
                    const SizedBox(height: 16),

                    // ── Form ─────────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _inputField("First Name", "Ahmed",
                                controller: _firstNameController),
                            const SizedBox(height: 16),
                            _inputField("Last Name", "Ahmed",
                                controller: _lastNameController),
                            const SizedBox(height: 16),

                            // ── City dropdown ─────────────────────────
                            _dropdownField(
                              label: "City",
                              hint: "Select city",
                              value: _selectedCity,
                              items: _wilayaBaladiyat.keys.toList(),
                              onChanged: (val) => setState(() {
                                _selectedCity    = val;
                                _selectedCommune = null;
                              }),
                            ),
                            const SizedBox(height: 16),

                            // ── Commune dropdown ──────────────────────
                            _dropdownField(
                              label: "Commune",
                              hint: _selectedCity == null
                                  ? "Select city first"
                                  : "Select commune",
                              value: _selectedCommune,
                              items: _communes,
                              enabled: _selectedCity != null,
                              onChanged: (val) =>
                                  setState(() => _selectedCommune = val),
                            ),
                            const SizedBox(height: 16),

                            // ── Birthday ──────────────────────────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Birthday",
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937))),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _pickBirthday,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      boxShadow: const [BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.05),
                                        offset: Offset(0, 1), blurRadius: 2)],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _birthday != null
                                              ? '${_birthday!.day.toString().padLeft(2, '0')}/'
                                                '${_birthday!.month.toString().padLeft(2, '0')}/'
                                                '${_birthday!.year}'
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _birthday != null
                                                ? const Color(0xFF1F2937)
                                                : const Color(0xFF9CA3AF)),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down,
                                            color: Color(0xFF6B7280)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Personal Description ──────────────────
                            _descriptionField(),
                            const SizedBox(height: 16),

                            _readOnlyField("Email Address", _email ?? ''),
                            const SizedBox(height: 16),
                            _readOnlyField("Phone Number", _phone ?? ''),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _inputField(String label, String hint,
      {TextEditingController? controller, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: Offset(0, 1), blurRadius: 2)],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              suffixIcon: icon != null
                  ? Icon(icon, color: const Color(0xFF6B7280)) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: enabled
                ? const [BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    offset: Offset(0, 1), blurRadius: 2)]
                : null,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: TextStyle(
                color: enabled
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFFCBD5E1),
                fontSize: 14, fontFamily: 'Lexend')),
              icon: Icon(Icons.keyboard_arrow_down,
                color: enabled
                    ? const Color(0xFF6B7280)
                    : const Color(0xFFCBD5E1)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14, fontFamily: 'Lexend'),
              onChanged: enabled ? onChanged : null,
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _descriptionField() {
    const int maxChars = 200;
    final int count = _descController.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Personal Description",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  offset: Offset(0, 1),
                  blurRadius: 2)
            ],
          ),
          child: TextField(
            controller: _descController,
            maxLines: 4,
            maxLength: maxChars,
            maxLengthEnforcement:
                MaxLengthEnforcement.enforced,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                const SizedBox.shrink(),
            decoration: const InputDecoration(
              hintText: 'Write something about you...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$count/$maxChars',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value.isNotEmpty ? value : '—',
                style: const TextStyle(color: Color(0xFF6B7280))),
              const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ],
    );
  }
}

