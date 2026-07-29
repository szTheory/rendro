import sys
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--file', required=True)
    parser.add_argument('--old', required=False)
    parser.add_argument('--new', required=False)
    parser.add_argument('--append', required=False)
    
    args = parser.parse_args()
    
    with open(args.file, 'r') as f:
        content = f.read()
        
    if args.old is not None and args.new is not None:
        with open(args.old, 'r') as f:
            old_str = f.read()
        with open(args.new, 'r') as f:
            new_str = f.read()
            
        if old_str not in content:
            print(f"Error: Could not find old string in {args.file}")
            sys.exit(1)
            
        content = content.replace(old_str, new_str)
        
    if args.append is not None:
        with open(args.append, 'r') as f:
            append_str = f.read()
        content += append_str
        
    with open(args.file, 'w') as f:
        f.write(content)
        
    print(f"Successfully updated {args.file}")

if __name__ == "__main__":
    main()
