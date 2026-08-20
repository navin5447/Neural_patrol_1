from app.database import SessionLocal
from app.models import User
from app.security import hash_password


def seed_demo_data():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.officer_id == "DEMO-001").first()
        if existing is None:
            user = User(
                officer_id="DEMO-001",
                name="Demo Officer",
                role="field_officer",
                password_hash=hash_password("demo1234"),
                status="active",
            )
            db.add(user)
            db.commit()
            print("Demo account seeded:")
            print("officer_id: DEMO-001")
            print("password: demo1234")
        else:
            print("Demo account already exists.")
    finally:
        db.close()


if __name__ == "__main__":
    seed_demo_data()
