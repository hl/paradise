# Design

```elixir
alias Paradise.Components
alias Ecto.UUID

# Astronaut
astronaut_entity = UUID.generate()

Components.Description.add(astronaut_entity, "Astronaut", persist: true)
Components.OxygenCapacity.add(astronaut_entity, 1000, persist: true)
Components.EnergyCapacity.add(astronaut_entity, 2000, persist: true)
Components.ImageFile.add(astronaut_entity, "astronaut.svg", persist: true)
Components.PlayerLevel.add(astronaut_entity, 1, persist: true)
Components.XPosition.add(astronaut_entity, Enum.random(1..100), persist: true)
Components.YPosition.add(astronaut_entity, Enum.random(1..100), persist: true)
Components.Playable.add(astronaut_entity, persist: true)
Components.Location.add(astronaut_entity, flagship_entity)

Components.OxygenLevel.add(astronaut_entity, 1000)
Components.EnergyLevel.add(astronaut_entity, 1800)
Components.XVelocity.add(astronaut_entity, 0)
Components.YVelocity.add(astronaut_entity, 0)

Components.Spawned.add(astronaut_entity)

# Credit
credit_entity = UUID.generate()

Components.Collectable.add(credit_entity)
Components.Currency.add(credit_entity)
Components.Description.add(credit_entity, "Credits")
Components.ImageFile.add(credit_entity, "credits.svg")
Components.ItemType.add(credit_entity, :currency)
Components.StackSize.add(credit_entity, nil)

# Backpack
backpack_entity = UUID.generate()

Components.Description.add(backpack_entity, "Backpack")
Components.Backpack.add(backpack_entity, astronaut_entity)
Components.SlotsAvailable.add(backpack_entity, 100)
Components.SlotsCapacity.add(backpack_entity, 100)

# Backpack Item - Credit
credit_item_entity = UUID.generate()

Components.Inventory.add(credit_item_entity, backpack_entity)
Components.InventoryItem.add(credit_item_entity, credit_entity)
Components.Quantity.add(credit_item_entity, 1000)

# Backpack Item - Terbium
terbium_item_entity = UUID.generate()

Components.Inventory.add(terbium_item_entity, terbium_entity)
Components.InventoryItem.add(terbium_item_entity, terbium_entity)
Components.Quantity.add(terbium_item_entity, 250)

# Backpack Item - Serandite
serandite_item_entity = UUID.generate()

Components.Inventory.add(serandite_item_entity, serandite_entity)
Components.InventoryItem.add(serandite_item_entity, serandite_entity)
Components.Quantity.add(serandite_item_entity, 250)

# Terbium Matter
terbium_entity = UUID.generate()

Components.Description.add(terbium_entity, "Terbium")
Components.Matter.add(terbium_entity, Components.Matter.metal())
Components.Rarity.add(terbuim_entity, Components.Rarity.common())
Components.StackSize.add(terbium_entity, 10)
Components.Harvestable.add(terbium_entity)

# Serandite Matter
serandite_entity = UUID.generate()

Components.Description.add(serandite_entity, "Serandite")
Components.Matter.add(terbium_entity, Components.Matter.mineral())
Components.Rarity.add(serandite_entity, Components.Rarity.rare())
Components.StackSize.add(serandite_entity, 10)
Components.Harvestable.add(serandite_entity)

# Rock
rock_entity = UUID.generate()

Components.Description.add(rock_entity, "Rock")
Components.XPosition.add(rock_entity, 10)
Components.YPosition.add(rock_entity, 10)

# Rock Element - Terbium
serandite_element_entity = UUID.generate()

Components.Quantity.add(serandite_element_entity, 200)
Components.Element.add(serandite_element_entity, serandite_entity)
Components.Element.add(serandite_element_entity, rock_entity)

# Rock Element - Serandite
terbium_element_entity = UUID.generate()

Components.Quantity.add(terbium_element_entity, 200)
Components.Element.add(terbium_element_entity, terbium_entity)
Components.Element.add(terbium_element_entity, rock_entity)

# Tree
tree_entity = UUID.generate()

Components.Description.add(tree_entity, "Redwood Tree")
Components.XPosition.add(tree_entity, 30)
Components.YPosition.add(tree_entity, 30)

# Wood
wood_entity = UUID.generate()

Components.Description.add(wood_entity, "Wood")
Components.StackSize.add(wood_entity, 20)
Components.Harvestable.add(wood_entity)
Components.Rarity.add(wood_entity, Components.Rarity.common())

# Tree Element - Wood
wood_element_entity = UUID.generate()

Components.Quantity.add(wood_element_entity, 20)
Components.Element.add(wood_element_entity, wood_entity)
Components.Element.add(wood_element_entity, tree_entity)

# Flagship
flagship_entity = UUID.generate()

Components.Description.add(flagship_entity, "Flagship", persist: true)
Components.ImageFile.add(flagship_entity, "flagship1.svg", persist: true)
Components.XPosition.add(flagship_entity, 0, persist: true)
Components.YPosition.add(flagship_entity, 0, persist: true)
Components.Gravity.add(flagship_entity, 100)
Components.Breathable.add(flagship_entity)

# Planet
planet_entity = UUID.generate()

Components.Description.add(planet_entity, "Calliope 3", persist: true)
Components.ImageFile.add(planet_entity, "map1.svg", persist: true)
Components.XPosition.add(planet_entity, 1, persist: true)
Components.YPosition.add(planet_entity, 0, persist: true)
Components.Gravity.add(planet_entity, 60)
```

### TODO
[ ] Tag locations (Visitable?)
[ ] Tag players
[ ] Tag elements like Rock, Tree, River, etc
[x] Figure out connection between Tree <> ... <> Wood
    Tree <Element> Wood Element <Element> Wood
[x] Rename ConsistsOf?
    ConstistsOf -> Element
