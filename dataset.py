# This file is responsible for generating synthetic datasets with random data for testing purposes.
# It fulfills the business requirement of creating mock data that can be used for testing data processing pipelines.

import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000  # Number of records to generate


def generate_random_email(null_percent: float = 20):
    """
    Generates a random email address with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of an email.
    :return: A random email address or None.
    """
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    if random.random() * 100 < null_percent:
        return None
    # Create a random email address with a random domain
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)


def generate_random_phone(null_percent: float = 20):
    """
    Generates a random phone number with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of a phone number.
    :return: A random phone number or None.
    """
    if random.random() * 100 < null_percent:
        return None
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"  # Random country code
    phone_number = ''.join(random.choices(string.digits, k=10))  # Random 10-digit phone number
    return f"{country_code} {phone_number}"


def generate_random_date(null_percent: float = 20):
    """
    Generates a random date between 2020-01-01 and 2023-01-01 with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of a date.
    :return: A random date or None.
    """
    if random.random() * 100 < null_percent:
        return None
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    # Generate a random date within the specified range
    return start_date + (end_date - start_date) * random.random()


def generate_random_alphanumeric(length=8, null_percent: float = 20):
    """
    Generates a random alphanumeric string of a given length with a certain percentage chance of returning None.

    :param length: The length of the alphanumeric string.
    :param null_percent: The percentage chance that the function will return None instead of an alphanumeric string.
    :return: A random alphanumeric string or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def generate_random_name(null_percent: float = 20):
    """
    Generates a random name from a predefined list with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of a name.
    :return: A random name or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])


def generate_random_age(null_percent: float = 20):
    """
    Generates a random age between 18 and 70 with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of an age.
    :return: A random age or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.randint(18, 70)


def generate_random_score(null_percent: float = 20):
    """
    Generates a random score between 0 and 100 with a certain percentage chance of returning None.

    :param null_percent: The percentage chance that the function will return None instead of a score.
    :return: A random score or None.
    """
    if random.random() * 100 < null_percent:
        return None
    return random.randint(0, 100)


def generate_random_boolean():
    """
    Generates a random boolean value.

    :return: A random boolean value (True or False).
    """
    return random.choice([True, False])


def generate_unique_ids(count, length=5):
    """
    Generates a list of unique alphanumeric IDs.

    :param count: The number of unique IDs to generate.
    :param length: The length of each ID.
    :return: A list of unique alphanumeric IDs.
    """
    unique_ids = set()
    while len(unique_ids) < count:
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)
    return list(unique_ids)


# Generate a dictionary of random data
data = {
    'UniqueID': generate_unique_ids(range_value),
    'Name': [generate_random_name() for _ in range(range_value)],
    'Age': [generate_random_age() for _ in range(range_value)],
    'Email': [generate_random_email() for _ in range(range_value)],
    'Phone': [generate_random_phone() for _ in range(range_value)],
    'JoinDate': [generate_random_date() for _ in range(range_value)],
    'Score': [generate_random_score() for _ in range(range_value)],
    'ID': [uuid.uuid4() for _ in range(range_value)],  # Generate unique UUIDs
    'Flag': [generate_random_boolean() for _ in range(range_value)],
}

# Create a DataFrame from the generated data
df = pd.DataFrame(data)

n = 270
# The following lines are commented out but are intended to sample rows from the DataFrame and concatenate them back.
# sampled_rows = df.sample(n=n, replace=False)
# df_updated = pd.concat([df, sampled_rows], ignore_index=True)

# Save the DataFrame to a CSV file
df.to_csv('generated_dataset.csv', index=False)

# Create a subset of the data for a second DataFrame
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

# Create another subset of the data for a third DataFrame
data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)
df2.to_csv('generated_dataset2.csv', index=False)