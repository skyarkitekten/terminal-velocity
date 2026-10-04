import unittest

from render_terraform_plan import render_plan


class RenderPlanTests(unittest.TestCase):
    def test_renders_statuses_summary_diff_and_run_link(self):
        body = render_plan(
            "prod",
            {
                "fmt": "success",
                "init": "success",
                "validate": "success",
                "plan": "failure",
            },
            "+1 ~2 -3 ±4",
            "Plan failed: authorization denied",
            "https://github.com/example/repo/actions/runs/123",
        )

        self.assertIn("<!-- terraform-plan: prod -->", body)
        self.assertIn("| plan | failure |", body)
        self.assertIn("**Changes:** `+1 ~2 -3 ±4`", body)
        self.assertIn("Plan failed: authorization denied", body)
        self.assertIn(
            "[View workflow run](https://github.com/example/repo/actions/runs/123)",
            body,
        )

    def test_truncation_keeps_tail_and_closes_markdown_blocks(self):
        plan = "beginning " + ("x" * 2_000) + "\nPlan summary: 1 to add, 2 to change"
        body = render_plan(
            "dev",
            {
                "fmt": "success",
                "init": "success",
                "validate": "success",
                "plan": "success",
            },
            "+1 ~2 -0 ±0",
            plan,
            "https://example.test/run",
            max_bytes=1_200,
        )

        self.assertLessEqual(len(body.encode("utf-8")), 1_200)
        self.assertIn("[Plan truncated; showing the tail of the output.]", body)
        self.assertIn("Plan summary: 1 to add, 2 to change", body)
        self.assertIn("</details>", body)
        self.assertIn("[View workflow run](https://example.test/run)", body)

    def test_truncation_respects_utf8_byte_limit(self):
        body = render_plan(
            "prod",
            {},
            "unavailable",
            ("é" * 2_000) + "final error",
            "https://example.test/run",
            max_bytes=1_200,
        )

        self.assertLessEqual(len(body.encode("utf-8")), 1_200)
        self.assertIn("final error", body)

    def test_uses_a_safe_fence_for_plan_backticks(self):
        body = render_plan(
            "dev",
            {},
            "unavailable",
            "example ``` value",
            "https://example.test/run",
        )

        self.assertIn("````\nexample ``` value\n````", body)


if __name__ == "__main__":
    unittest.main()
