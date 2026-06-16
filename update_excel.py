import pandas as pd

# The 150 labels determined by Gemini
labels = [
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
    0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 
    0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 
    0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 
    0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 
    0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 
    0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 
    0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
    0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 
    1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 
    1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 
    0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 
    1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 
    0, 0, 1, 0, 1, 0, 0, 1, 1, 0
]

df = pd.read_excel('sampled_constructivity.xlsx')

if len(df) == len(labels):
    df['Constructivity_Gemini'] = labels
    df.to_excel('sampled_constructivity.xlsx', index=False)
    print("Successfully updated sampled_constructivity.xlsx with Gemini classifications.")
else:
    print(f"Error: Number of rows in excel ({len(df)}) does not match number of labels ({len(labels)}).")
