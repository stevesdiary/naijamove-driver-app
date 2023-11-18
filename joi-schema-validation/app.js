const express = require('express');
const logger = require('morgan');
const bodyParser = require('body-parser');
const Routes = require('./routes');

const app = express();
const port = process.env.NODE_ENV || 3001;
app.use(logger('dev'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}))

// app configurations
app.set('port', port);

app.use('/', Routes);

app.post('/test', (req, res, next) => {
  const Joi = require('joi');

  const data = req.body;
  const schema = Joi.object().keys({
    email: Joi.string().email().required(),
    phone: Joi.string().regex(/^\d{3}-\d{3}-\d{4}$/).required(),
    birthday: Joi.date().max('1-1-2004').iso()
  });
   Joi.validate(data, schema, (err, value) => {
      const id = Math.ceil(Math.random() * 9999999);

      if (err) {
      res.status(422).json({
         status: 'error',
         message: 'Invalid request data',
         data: data
      });
      } else {
      res.json({
         status: 'success',
         message: 'User created successfully',
         data: Object.assign({id}, value)
      });
      }
   });
});

// establish http server connection
app.listen(port, () => { console.log(`App running on port ${port}`) });