import sys, os, re, subprocess

result_stem = sys.argv[1]
experiment = sys.argv[2]


ssub_path = '/media/labs/rsmith/lab-members/cgoldman/Wellbeing/social_media/scripts/run_social.ssub'

room_type = ["Like", "Dislike"]
model_type = ["kf","logistic"]
for room in room_type:
    for model in model_type:

        results = result_stem + experiment + "/" + model + "/"
        
        if not os.path.exists(results):
            os.makedirs(results)
            print(f"Created results directory {results}")

        if not os.path.exists(f"{results}/logs"):
            os.makedirs(f"{results}/logs")
            print(f"Created results-logs directory {results}/logs")




        stdout_name = f"{results}/logs/social-{model}_model-{room}_room-%J.stdout"
        stderr_name = f"{results}/logs/social-{model}_model-{room}_room-%J.stderr"
        jobname = f'social-{model}_model-{room}_room'
        os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {results} {model} {room} {experiment}")

        print(f"SUBMITTED JOB [{jobname}]")

# python3 /media/labs/rsmith/lab-members/cgoldman/Wellbeing/social_media/scripts/runall_social.py /media/labs/rsmith/lab-members/cgoldman/Wellbeing/social_media/output/SM_fits_7-24-24/ "prolific"