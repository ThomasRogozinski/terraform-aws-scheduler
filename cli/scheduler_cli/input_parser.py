class Object(object):
    pass

def parse_input():
    args = Object() 
    args.name = select_input('Which lambda function would you like to trigger?', 'Name') 
    args.action = select_choice('Which lambda action would you like to trigger?', ['start', 'stop', 'enable', 'disable']) 
    args.ec2 = True if select_choice('Would you like to process EC2s?', ['yes', 'no']) == 'yes' else False
    args.asg = True if select_choice('Would you like to process ASGs?', ['yes', 'no']) == 'yes' else False
    args.rds = True if select_choice('Would you like to process RDSs?', ['yes', 'no']) == 'yes' else False
    args.tags = select_input('Which tags would you like to target?', 'List of tags').split()
    return args


def select_input(question, desc):
    prompt = '\n' + ('\n').join([question, (u"%s: " % (desc)) ])
    reply = input(prompt)
    return reply


def select_choice(question, choices):
    choices = list(choices)
    prompt = '\n' + ('\n').join([question,
        "\n".join([
            (u"          %i. %s" % (i, choice))
            for i, choice in enumerate(choices, start=1)
        ]),
    ])
    print(prompt)

    while True:
        reply = input("Choice: ")
        if reply.isdigit():
            index = int(reply) - 1
            if 0 <= index < len(choices):
                return choices[index]
        print('Error: invalid choice: {0}. (choice from 1 to {1})'.format(index, len(choices)))
