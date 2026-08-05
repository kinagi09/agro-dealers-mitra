from django.core.management.base import BaseCommand
from licenses.models import FertilizerType


class Command(BaseCommand):
    help = "Seeds the standard list of fertilizer types"

    def handle(self, *args, **kwargs):
        names = [
            "Straight Nitrogenous Fertilizers",
            "Straight Phosphatic Fertilizers",
            "Straight Potassium Fertilizers",
            "Straight Sulphur Fertilizers",
            "N.P. Complex Fertilizers",
            "N.P.K. Complex Fertilizers",
            "Micronutrient Fertilizers",
            "Fortified Fertilizers",
            "100% Water Soluble Complex Fertilizers",
            "100% Water Soluble Mixture Fertilizers",
            "State Grade Micronutrient Fertilizers",
            "Beneficial Element Fertilizers",
            "Liquid Fertilizers",
            "Biofertilizers",
            "Organic Fertilizers",
            "Non-Edible De-oiled Cake Fertilizers",
            "Biostimulants",
        ]
        for name in names:
            obj, created = FertilizerType.objects.get_or_create(name=name)
            if created:
                self.stdout.write(f"  + Created: {name}")
        self.stdout.write(self.style.SUCCESS(f"{len(names)} fertilizer types ready."))