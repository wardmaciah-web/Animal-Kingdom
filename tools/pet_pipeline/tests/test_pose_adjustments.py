import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('pose',Path(__file__).parents[1]/'workers/pose_adjustments.py')
pose=importlib.util.module_from_spec(spec);spec.loader.exec_module(pose)


class PoseAdjustments(unittest.TestCase):
    def test_paw_moves_but_outside_torso_is_preserved(self):
        op={'bounds':[[-1,1],[-1,1],[0,1]],'translation':[0,0,-.1],'feather':.1}
        self.assertEqual(pose.deform_point((0,0,.5),op)[0],(0,0,.4))
        self.assertEqual(pose.deform_point((0,0,1.5),op),((0,0,1.5),0))
        self.assertEqual(pose.deform_point((0,0,1),op),((0,0,1),0))

    def test_joint_rotation_uses_authored_pivot(self):
        op={'bounds':[[-2,2],[-2,2],[-2,2]],'pivot':[1,0,0],'rotation_degrees':[0,0,90]}
        point,_=pose.deform_point((1,1,0),op)
        for actual,expected in zip(point,(0,0,0)):self.assertAlmostEqual(actual,expected)

    def test_soft_selection_and_scale(self):
        op={'bounds':[[-1,1],[-1,1],[0,1]],'translation':[0,0,-.1],'feather':.2}
        point,weight=pose.deform_point((0,0,.1),op)
        self.assertAlmostEqual(weight,.5)
        self.assertAlmostEqual(point[2],.05)
        scaled,_=pose.deform_point((0,0,.2),op,2)
        self.assertAlmostEqual(scaled[2],.1)
