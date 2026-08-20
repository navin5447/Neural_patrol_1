from demo.demo_data_generator import build_demo_case
from cv.strip_validator import validate_strip


def run_integration_demo():
    case = build_demo_case()
    assert case["case"]["case_number"] == "CHD-2026-041"
    assert case["sample"]["sample_id"] == "NP-CHD-2026-000128"
    validation = validate_strip("dummy_test_image.png")
    assert validation.control_valid is True
    assert validation.target == "BUFFALO"
    print("Integration demo passed for case CHD-2026-041")


if __name__ == "__main__":
    run_integration_demo()
