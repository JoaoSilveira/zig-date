/*
http://sites.millersville.edu/bikenaga/number-theory/calendar/calendar.html
https://docs.rs/crate/chrono/0.4.0/source/src/ 
*/

// const out = document.getElementById('out');
// const days = dateToDays(1991, 2, 1);

// out.textContent = JSON.stringify(daysToDate(days));

function test() {
  // let leap = 0;
  let days = 0;

  for (let year = 1; year < 3000; year++) {
    const isLeap = isLeapYear(year);
    const daysInYear = 365 + Number(isLeap);
    // leap += Number(isLeap);

    for (let day = 1; day < daysInYear; day++) {
      if (isLeap && day < 60) {
        if (leapDaysInYear(year) - 1 !== leapDaysInDays(days + day)) {
          console.log(`${year}: ${leapDaysInYear(year) - 1} ${leapDaysInDays(days + day)} || ${day}`);
        }
      } else {
        if (leapDaysInYear(year) !== leapDaysInDays(days + day)) {
          console.log(`${year}: ${leapDaysInYear(year)} ${leapDaysInDays(days + day)} || ${day}`);
        }
      }

      // if (leapDaysInYear(year) !== leapDaysInDays(days + day)) {
      //   console.log(`${year}: ${leapDaysInYear(year)} ${leapDaysInDays(days + day)} || ${day}`);
      // }
    }

    days += daysInYear;
  }
}

function makingDates() {
  let accDays = 0;
  let leaps = 0;

  for(let year = 1; year <= 3000; year++) {
    let daysOfYear = 0;
    const daysInMonth = [31, 28 + isLeapYear(year), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    for(let month = 1; month <= 12; month++) {
      const totalDays = daysInMonth[month - 1];

      for (let day = 1; day <= totalDays; day++) {
        accDays++;
        daysOfYear++;

        if (month !== monthFromDays(daysOfYear, isLeapYear(year))) {
          console.log(`${month} - ${monthFromDays(daysOfYear, isLeapYear(year))}`);
        }
        // if (day === 29 && month === 2) {
        //   console.log(`${year}-${month}-${day}: ${accDays} ${(accDays - leaps - 1155) % 1460}`);
        //   leaps++;
        // }
      }
    }
  }
}

function monthFromDays(days, leap) {
  const acc_days = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
  
  days -= Number(days >= 60 && leap);
  const index = Math.trunc((days - 1) / 31);
  
  return index + 2 - Number(days <= acc_days[index]);
}

function monthFromDaysLoop(days) {
  const acc_days = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
  for (let i = 1; i < acc_days.length; i++) {
    if (days <= acc_days[i]) return i;
  }

  return 12;
}

function daysToDate(days) {
  const acc_days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  const acc_days_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335];
  const leapDays = leapDaysInDays(days);
  days -= leapDays;

  const year = Math.trunc(days / 365);
  const leap = isLeapYear(year);
  days = days - year * 365;
  const month = monthFromIndex(days);
  const day = days - (leap ? acc_days_leap[month - 1] : acc_days[month - 1]);

  return {
    days: days,
    year: year,
    month: month,
    day: day,
    leap: leap,
  };
}

function dateToDays(year, month, day) {
  const days_in_month = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  return day + days_in_month[month - 1] + year * 365 + leapDaysInYear(year - Number(month < 3)) + Number(isLeapYear(year) && month >= 3);
}

function leapDaysInYear(year) {
  return Math.trunc(year / 4) - Math.trunc(year / 100) + Math.trunc(year / 400);
}

// problem, if days is between leap day and the last year's day
// this function will not count it
function leapDaysInDays(days) {
  const quad = Math.trunc(days / 146097); // 146000 days + 97 leap days (400 years)
  let acc = days - quad * 146097;
  const cent = Math.trunc(acc / 36524); // 36500 days + 24 leap days (100 years)
  acc = acc - (cent - Number(cent === 4)) * 36524;
  const four = Math.trunc(acc / 1461); // 1460 days + 1 leap day (4 years)
  acc = acc - four * 1461;
  const one = Math.trunc(acc / 365);
  acc = acc - (cent - Number(one === 4)) * 365;

  return four - cent + quad;
}

function isLeapYear(year) {
  return (year % 4 === 0 && year % 100 !== 0) || year % 400 === 0;
}

makingDates();