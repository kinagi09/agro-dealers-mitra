from django.core.management.base import BaseCommand
from licenses.models import State, District, Taluka


class Command(BaseCommand):
    help = "Seeds Karnataka state, its 31 districts, and all talukas as a starting dataset"

    def handle(self, *args, **kwargs):
        state, _ = State.objects.get_or_create(name="Karnataka")
        self.stdout.write(self.style.SUCCESS(f"State ready: {state.name}"))

        # district name -> list of taluka names
        district_taluka_map = {
            "Bagalkot": [
                "Bagalkot", "Jamkhandi", "Mudhol", "Badami", "Bilgi",
                "Hungund", "Ilkal", "Rabkavi Banhatti", "Guledgudda",
            ],
            "Ballari": [
                "Ballari", "Kurugodu", "Kampli", "Sanduru", "Siraguppa",
            ],
            "Belagavi": [
                "Belagavi", "Athani", "Bailhongal", "Chikkodi", "Gokak",
                "Khanapura", "Mudalgi", "Nippani", "Rayabaga", "Savadatti",
                "Ramadurga", "Kagawada", "Hukkeri", "Kitturu", "Yargatti",
            ],
            "Bengaluru Urban": [
                "Bengaluru", "Kengeri", "Krishnarajapura", "Anekal", "Yelahanka",
            ],
            "Bengaluru Rural": [
                "Nelamangala", "Doddaballapura", "Devanahalli", "Hosakote",
            ],
            "Bidar": [
                "Aurad", "Basavakalyana", "Bhalki", "Bidar", "Chitgoppa",
                "Hulsuru", "Humnabad", "Kamalanagara",
            ],
            "Chamarajanagar": [
                "Chamarajanagara", "Gundlupete", "Kollegala", "Yelanduru", "Hanuru",
            ],
            "Chikballapur": [
                "Chikkaballapura", "Bagepalli", "Chintamani", "Gauribidanuru",
                "Gudibanda", "Sidlaghatta", "Cheluru", "Manchenahalli",
            ],
            "Chikkamagaluru": [
                "Chikkamagaluru", "Kaduru", "Koppa", "Mudigere",
                "Narasimharajapura", "Sringeri", "Tarikere", "Ajjampura", "Kalasa",
            ],
            "Chitradurga": [
                "Chitradurga", "Challakere", "Hiriyur", "Holalkere",
                "Hosadurga", "Molakalmuru",
            ],
            "Dakshina Kannada": [
                "Mangaluru", "Ullal", "Mulki", "Moodbidri", "Bantwala",
                "Belathangadi", "Putturu", "Sulya", "Kadaba",
            ],
            "Davanagere": [
                "Davanagere", "Harihara", "Channagiri", "Honnali",
                "Nyamathi", "Jagaluru",
            ],
            "Dharwad": [
                "Kalghatgi", "Dharwad", "Hubballi (Rural)", "Hubballi (Urban)",
                "Kundagolu", "Navalgunda", "Alnavara", "Annigeri",
            ],
            "Gadag": [
                "Gadag", "Naragunda", "Mundaragi", "Rona",
                "Gajendragada", "Lakshmeshwara", "Shirahatti",
            ],
            "Hassan": [
                "Hassan", "Arasikere", "Channarayapattana", "Holenarsipura",
                "Sakleshpura", "Aluru", "Arakalagudu", "Beluru",
            ],
            "Haveri": [
                "Ranibennur", "Byadgi", "Hangala", "Haveri", "Savanuru",
                "Hirekeruru", "Shiggavi", "Rattihalli",
            ],
            "Kalaburagi": [
                "Kalaburagi", "Afzalpura", "Alanda", "Chincholi", "Chitapura",
                "Jevargi", "Sedam", "Kamalapura", "Shahabad", "Kalgi", "Yedrami",
            ],
            "Kodagu": [
                "Madikeri", "Somawarapete", "Virajapete", "Ponnammapete", "Kushalnagara",
            ],
            "Kolar": [
                "Kolar", "Bangarapete", "Maluru", "Mulabagilu",
                "Srinivasapura", "Kolar Gold Fields (Robertsonpete)",
            ],
            "Koppal": [
                "Koppala", "Gangavathi", "Kushtagi", "Yelaburga",
                "Kanakagiri", "Karatagi", "Kukanuru",
            ],
            "Mandya": [
                "Mandya", "Madduru", "Malavalli", "Srirangapattana",
                "Krishnarajapete", "Nagamangala", "Pandavapura",
            ],
            "Mysuru": [
                "Mysuru", "Hunasuru", "Krishnarajanagara", "Nanjanagodu",
                "Heggadadevanakote", "Piriyapattana", "Tirumakudalu Narasipura",
                "Saraguru", "Saligrama",
            ],
            "Raichur": [
                "Raichuru", "Sindhanuru", "Manvi", "Devadurga",
                "Lingasaguru", "Mudgal", "Maski", "Sirawara",
            ],
            "Ramanagara": [
                "Ramanagara", "Magadi", "Kanakapura", "Channapattana", "Harohalli",
            ],
            "Shivamogga": [
                "Shivamogga", "Sagara", "Bhadravathi", "Hosanagara",
                "Shikaripura", "Soraba", "Tirthahalli",
            ],
            "Tumakuru": [
                "Tumakuru", "Chikkanayakanahalli", "Kunigal", "Madhugiri",
                "Sira", "Tipturu", "Gubbi", "Koratagere", "Pavagada", "Turuvekere",
            ],
            "Udupi": [
                "Udupi", "Kapu", "Bynduru", "Karkala", "Kundapura",
                "Hebri", "Brahmavara",
            ],
            "Uttara Kannada": [
                "Karwara", "Sirsi", "Joida", "Dandeli", "Bhatkal", "Kumta",
                "Ankola", "Haliyal", "Honnavara", "Mundagodu", "Siddapura", "Yellapura",
            ],
            "Vijayapura": [
                "Vijayapura", "Indi", "Basavana Bagewadi", "Sindgi",
                "Muddebihala", "Talikote", "Devara Hipparagi", "Chadchana",
                "Tikote", "Babaleshwara", "Kolhara", "Nidagundi", "Alamela",
            ],
            "Yadgir": [
                "Yadagiri", "Shahapura", "Surapura", "Gurmitkala",
                "Vadagera", "Hunsagi",
            ],
            "Vijayanagara": [
                "Hosapete", "Hagaribommanahalli", "Harapanahalli",
                "Hoovina Hadagali", "Kudligi", "Kotturu",
            ],
        }

        districts = {}
        for name in district_taluka_map.keys():
            district, created = District.objects.get_or_create(state=state, name=name)
            districts[name] = district
            if created:
                self.stdout.write(f"  + District created: {name}")

        self.stdout.write(self.style.SUCCESS(f"{len(district_taluka_map)} districts ready."))

        total_talukas = 0
        for district_name, taluka_names in district_taluka_map.items():
            district = districts[district_name]
            for taluka_name in taluka_names:
                taluka, created = Taluka.objects.get_or_create(
                    district=district, name=taluka_name
                )
                total_talukas += 1
                if created:
                    self.stdout.write(f"    + Taluka created: {taluka_name} ({district_name})")

        self.stdout.write(self.style.SUCCESS(f"{total_talukas} talukas ready across all districts."))
        self.stdout.write(self.style.SUCCESS("Seeding complete."))