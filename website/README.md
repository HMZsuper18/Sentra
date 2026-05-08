# Website - Robot Dashboard

Firebase-hosted web dashboard for robot monitoring and control.

## Structure

```
website/
├── index.html     # Main dashboard page
├── 404.html       # Error page
├── app/           # Firebase app config
├── assets/        # Static assets (images, icons)
├── firebase.json  # Firebase hosting config
└── database.rules.json
```

## Features

- Real-time Firebase connection for command display
- Mobile-responsive dark theme dashboard
- Command history log
- Error status panel

## Firebase

- **Realtime Database**: Stores current command
- **Hosting**: Firebase static hosting
- **Auth**: Database authentication token

## API

### Read Command
```
GET /command/word.json
```

### Write Command
```
PUT /command/word.json
{"word": "قدام"}
```

## Deployment

```bash
firebase deploy
```