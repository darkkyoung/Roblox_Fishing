"""Negative regressions for the P0 persistent-transform defect (no Studio)."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('place', ROOT/'scripts/validate_place.py')
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)


class SerializationRegression(unittest.TestCase):
    def setUp(self):
        self.tree = ET.parse(ROOT/'build/FILAMENT-Fishing-0.2.rbxlx')
        self.expected = v.expected_geometry(json.loads((ROOT/'config/zones.json').read_text()))
        self.world = json.loads((ROOT/'src/world.model.json').read_text())

    def test_all_75_transforms_match_independent_zone_specification(self):
        actual = v.xml_geometry(self.tree)
        v.compare_geometry(actual, self.expected, 'XML')
        self.assertEqual(sum(map(len, actual.values())), 75)
        self.assertTrue(v.close(actual['Workspace/World/Zones/AquariumPlot12/Floor'][0][1][:3], [76, 1.2, -113]))

    def test_original_position_only_defect_is_rejected(self):
        for item in self.tree.findall('.//Item'):
            if item.get('class') in v.BASE_PARTS:
                frame = v.prop(item, 'CFrame')
                item.find('Properties').remove(frame)
                p = ET.SubElement(item.find('Properties'), 'Vector3', name='Position')
                for component in ['X', 'Y', 'Z']:
                    ET.SubElement(p, component).text = frame.find(component).text
        with self.assertRaisesRegex(AssertionError, 'forbidden serialized Position'):
            v.xml_geometry(self.tree)

    def test_missing_and_malformed_cframes_are_rejected(self):
        item = next(i for i in self.tree.findall('.//Item') if i.get('class') == 'Part')
        frame = v.prop(item, 'CFrame')
        frame.remove(frame.find('R22'))
        with self.assertRaisesRegex(AssertionError, 'CFrame components'):
            v.xml_geometry(self.tree)
        item.find('Properties').remove(frame)
        with self.assertRaisesRegex(AssertionError, 'exactly one'):
            v.xml_geometry(self.tree)

    def test_wrong_coordinate_in_every_geometry_category_is_rejected(self):
        actual = v.xml_geometry(self.tree)
        paths = ['Zones/AquariumPlot12/Floor', 'Zones/SpawnPlaza/Spawn', 'Paths/WestWalk',
                 'LakeSafety/LakeGuard2', 'Boundary', 'Zones/FishMarket/Console',
                 'Zones/FeedWorkshop/Sign', 'Zones/AquariumPlot01/OwnerSign', 'Ground']
        for suffix in paths:
            with self.subTest(part=suffix):
                changed = copy.deepcopy(actual)
                changed['Workspace/World/'+suffix][0][1][0] += 1
                with self.assertRaises(AssertionError):
                    v.compare_geometry(changed, self.expected, suffix)

    def test_rotation_and_nonfinite_coordinates_are_rejected(self):
        for component, value in [(3, 0), (0, float('nan')), (1, float('inf'))]:
            actual = v.xml_geometry(self.tree)
            actual['Workspace/World/Ground'][0][1][component] = value
            with self.assertRaises(AssertionError):
                v.compare_geometry(actual, self.expected, 'invalid CFrame')

    def test_missing_spawn_or_extra_part_is_rejected(self):
        actual = v.xml_geometry(self.tree)
        del actual['Workspace/World/Zones/SpawnPlaza/Spawn']
        with self.assertRaises(AssertionError):
            v.compare_geometry(actual, self.expected, 'missing spawn')
        actual = v.xml_geometry(self.tree)
        actual['Workspace/World/Ground'].append(actual['Workspace/World/Ground'][0])
        with self.assertRaises(AssertionError):
            v.compare_geometry(actual, self.expected, 'duplicate')

    def test_generated_json_must_use_twelve_component_cframe(self):
        ground = self.world['Children'][0]['Properties']
        ground['Position'] = ground.pop('CFrame')[:3]
        with self.assertRaisesRegex(AssertionError, 'Position'):
            v.model_geometry(self.world)


if __name__ == '__main__':
    unittest.main(verbosity=2)
