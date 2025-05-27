import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000


def generate_random_email(null_percent: float = 20):
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    if random.random() * 100 < null_percent:
        return None
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)


def generate_random_phone(null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"
    phone_number = ''.join(random.choices(string.digits, k=10))
    return f"{country_code} {phone_number}"


def generate_random_date(null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    return start_date + (end_date - start_date) * random.random()


def generate_random_alphanumeric(length=8, null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def generate_random_name(null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])


def generate_random_age(null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    return random.randint(18, 70)


def generate_random_score(null_percent: float = 20):
    if random.random() * 100 < null_percent:
        return None
    return random.randint(0, 100)


def generate_random_boolean():
    return random.choice([True, False])

def generate_unique_ids(count, length=5):
    unique_ids = set()
    while len(unique_ids) < count:
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)
    return list(unique_ids)


data = {
    'UniqueID': generate_unique_ids(range_value),
    'Name': [generate_random_name() for _ in range(range_value)],
    'Age': [generate_random_age() for _ in range(range_value)],
    'Email': [generate_random_email() for _ in range(range_value)],
    'Phone': [generate_random_phone() for _ in range(range_value)],
    'JoinDate': [generate_random_date() for _ in range(range_value)],
    'Score': [generate_random_score() for _ in range(range_value)],
    'ID': [uuid.uuid4() for _ in range(range_value)],
    'Flag': [generate_random_boolean() for _ in range(range_value)],
}

df = pd.DataFrame(data)

n = 270
# sampled_rows = df.sample(n=n, replace=False)
# df_updated = pd.concat([df, sampled_rows], ignore_index=True)

# df_updated.to_csv('generated_dataset.csv', index=False)
df.to_csv('generated_dataset.csv', index=False)

data1 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Name': data['Name'],
    'Age': data['Age'],
    'Email': data['Email'],
    'Phone': data['Phone'],
    'JoinDate': data['JoinDate'],
    'Flag': data['Flag'],
}
df1 = pd.DataFrame(data1)
df1.to_csv('generated_dataset1.csv', index=False)

data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)
df2.to_csv('generated_dataset2.csv', index=False)
