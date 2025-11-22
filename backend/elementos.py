import ifcopenshell

ifc = ifcopenshell.open("ifc2.ifc")

tipos = {}

for e in ifc.by_type("IfcBuildingElement"):
    tipos[e.is_a()] = tipos.get(e.is_a(), 0) + 1

print(tipos)
