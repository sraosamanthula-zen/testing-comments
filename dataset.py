import pandas as pd
import numpy as np
import random
import string
import uuid

range_value = 1000

def generate_random_email(null_percent: float = 20):
    """
    Generates a random email address with a specified percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of an email.
        
    Returns:
        str or None: Random email address or None.
    """
    domains = ["gmail.com", "yahoo.com", "hotmail.com"]
    if random.random() * 100 < null_percent:
        return None
    # Generate random username and append a random domain
    return ''.join(random.choices(string.ascii_lowercase, k=random.randint(5, 7))) + '@' + random.choice(domains)

def generate_random_phone(null_percent: float = 20):
    """
    Generates a random phone number with a specified percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of a phone number.
        
    Returns:
        str or None: Random phone number or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate random country code and phone number
    country_code = f"+{random.choice(['91', '01', '44', '81', '61'])}"
    phone_number = ''.join(random.choices(string.digits, k=10))
    return f"{country_code} {phone_number}"

def generate_random_date(null_percent: float = 20):
    """
    Generates a random date within a specified range with a percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of a date.
        
    Returns:
        pd.Timestamp or None: Random date or None.
    """
    if random.random() * 100 < null_percent:
        return None
    start_date = pd.to_datetime('2020-01-01')
    end_date = pd.to_datetime('2023-01-01')
    # Calculate random date between start_date and end_date
    return start_date + (end_date - start_date) * random.random()

def generate_random_alphanumeric(length=8, null_percent: float = 20):
    """
    Generates a random alphanumeric string of a specified length with a percentage chance of returning None.
    
    Args:
        length (int): Length of the alphanumeric string.
        null_percent (float): Percentage chance to return None instead of a string.
        
    Returns:
        str or None: Random alphanumeric string or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate random alphanumeric string
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_random_name(null_percent: float = 20):
    """
    Generates a random name from a predefined list with a percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of a name.
        
    Returns:
        str or None: Random name or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Select random name from list
    return random.choice(['Alice', 'Bob', 'Charlie', 'David', 'Eve'])

def generate_random_age(null_percent: float = 20):
    """
    Generates a random age within a specified range with a percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of an age.
        
    Returns:
        int or None: Random age or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate random age between 18 and 70
    return random.randint(18, 70)

def generate_random_score(null_percent: float = 20):
    """
    Generates a random score within a specified range with a percentage chance of returning None.
    
    Args:
        null_percent (float): Percentage chance to return None instead of a score.
        
    Returns:
        int or None: Random score or None.
    """
    if random.random() * 100 < null_percent:
        return None
    # Generate random score between 0 and 100
    return random.randint(0, 100)

def generate_random_boolean():
    """
    Generates a random boolean value.
    
    Returns:
        bool: Random boolean value.
    """
    # Randomly choose between True and False
    return random.choice([True, False])

def generate_unique_ids(count, length=5):
    """
    Generates a list of unique alphanumeric IDs.
    
    Args:
        count (int): Number of unique IDs to generate.
        length (int): Length of each ID.
        
    Returns:
        list: List of unique alphanumeric IDs.
    """
    unique_ids = set()
    while len(unique_ids) < count:
        # Generate random unique ID
        uid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))
        unique_ids.add(uid)
    return list(unique_ids)

# Generate data using the defined functions
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

# Create DataFrame from generated data
df = pd.DataFrame(data)

n = 270
# The following lines are commented out and not used in the current logic
# sampled_rows = df.sample(n=n, replace=False)
# df_updated = pd.concat([df, sampled_rows], ignore_index=True)

# Save the DataFrame to a CSV file
df.to_csv('generated_dataset.csv', index=False)

# Create a subset of the data for another CSV file
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

# Create another subset of the data for a different CSV file
data2 = {
    'UniqueID': data['UniqueID'],
    'ID': data['ID'],
    'Score': data['Score'],
}
df2 = pd.DataFrame(data2)
df2.to_csv('generated_dataset2.csv', index=False)