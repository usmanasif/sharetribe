import React, { PropTypes } from 'react';
import css from './styles.scss';

import GuideBackToTodoLink from './GuideBackToTodoLink';

const GuideFilterPage = (props) => (
  <div className="container">
    <GuideBackToTodoLink
      changePage={props.changePage}
      initialPath={props.initialPath}
      t={props.t}
    />

    <h2 className={css.title} >{props.t('title')}</h2>

    <p className={css.description} >
      {props.t('description_p1')}
    </p>
    <p className={css.description} >
      {props.t('description_p2')}
    </p>

    {props.pageData.info_image ?
      <div className={css.sloganImageContainerBig} >
        <img src={props.pageData.info_image}
          className={css.sloganImage}
          alt={props.t('info_image_alt')}
        />
      </div>
      : null}

    <div className={css.infoTextContainer} >
      <div className={css.infoTextIcon}
        dangerouslySetInnerHTML={{ __html: props.infoIcon }}
      ></div>
      <div className={css.infoTextContent}
        dangerouslySetInnerHTML={{ __html: props.t('advice') }}
      ></div>
    </div>

    <a href={props.pageData.link}
      className={css.nextButton}
    >
      {props.t('add_fields_and_filters')}
    </a>
  </div>
);

GuideFilterPage.propTypes = {
  changePage: PropTypes.func.isRequired,
  initialPath: PropTypes.string.isRequired,
  t: PropTypes.func.isRequired,
  infoIcon: PropTypes.string.isRequired,
  pageData: PropTypes.shape({
    link: PropTypes.string.isRequired,
    info_image: PropTypes.string,
  }).isRequired,
};

export default GuideFilterPage;
